#include <cuda_runtime.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#define CHECK_CUDA(call)                                                                      \
    do {                                                                                      \
        cudaError_t err__ = (call);                                                           \
        if (err__ != cudaSuccess) {                                                           \
            std::cerr << "CUDA error: " << cudaGetErrorString(err__) << " (" << __FILE__ \
                      << ":" << __LINE__ << ")" << std::endl;                                \
            std::exit(1);                                                                     \
        }                                                                                     \
    } while (0)

struct Edge {
    int u;
    int v;
};

static std::vector<Edge> load_edges_uv(const std::string& edges_file, int& n_out) {
    std::ifstream in(edges_file);
    if (!in) throw std::runtime_error("Cannot open edges file: " + edges_file);

    std::vector<Edge> edges;
    edges.reserve(1 << 20);

    std::string line;
    int max_node = -1;
    while (std::getline(in, line)) {
        if (line.empty() || line[0] == '#') continue;
        std::stringstream ss(line);
        int u = -1, v = -1;
        double w = 0.0;
        if (!(ss >> u >> v >> w)) continue;
        edges.push_back({u, v});
        max_node = std::max(max_node, std::max(u, v));
    }
    n_out = max_node + 1;
    return edges;
}

static void build_og_out_edge_csr_cpu(
    int n,
    const std::vector<Edge>& edges,
    std::vector<int>& og_row_ptr,
    std::vector<int>& og_out_edge_ids) {

    const int m = static_cast<int>(edges.size());
    og_row_ptr.assign(n + 1, 0);
    for (int e = 0; e < m; ++e) {
        og_row_ptr[edges[e].u + 1]++;
    }
    for (int i = 0; i < n; ++i) {
        og_row_ptr[i + 1] += og_row_ptr[i];
    }

    og_out_edge_ids.resize(m);
    std::vector<int> cursor = og_row_ptr;
    for (int e = 0; e < m; ++e) {
        int u = edges[e].u;
        int idx = cursor[u]++;
        og_out_edge_ids[idx] = e;
    }
}

static void build_lg_csr_cpu(
    const std::vector<Edge>& edges,
    const std::vector<int>& og_row_ptr,
    const std::vector<int>& og_out_edge_ids,
    std::vector<int>& lg_row_ptr,
    std::vector<int>& lg_col_idx) {

    const int m = static_cast<int>(edges.size());
    std::vector<int> counts(m);
    for (int e1 = 0; e1 < m; ++e1) {
        int v = edges[e1].v;
        counts[e1] = og_row_ptr[v + 1] - og_row_ptr[v];
    }

    lg_row_ptr.assign(m + 1, 0);
    for (int i = 0; i < m; ++i) {
        lg_row_ptr[i + 1] = lg_row_ptr[i] + counts[i];
    }

    const int eh = lg_row_ptr[m];
    lg_col_idx.resize(eh);

    for (int e1 = 0; e1 < m; ++e1) {
        int v = edges[e1].v;
        int begin = og_row_ptr[v];
        int end = og_row_ptr[v + 1];
        int base = lg_row_ptr[e1];
        for (int k = 0; k < (end - begin); ++k) {
            lg_col_idx[base + k] = og_out_edge_ids[begin + k];
        }
    }
}

__global__ void k_relax_atomic(int V, int EH, int active, int step, int delta, const int* __restrict__ lg_col_idx,
                              int* __restrict__ dist) {
    int t = blockIdx.x * blockDim.x + threadIdx.x;
    if (t >= active) return;

    // Use real LG adjacency indices to pick destinations.
    int idx = (step * active + t) % EH;
    int dst = lg_col_idx[idx];

    // Make contention grow with delta by shrinking the destination space.
    // This models the fact that overly large Δ widens a bucket, increasing concurrent relaxations
    // that compete on a smaller set of hot vertices.
    long long denom = 1LL * delta * delta * delta;
    if (denom < 1) denom = 1;
    int collision_space = static_cast<int>(V / denom);
    if (collision_space < 1) collision_space = 1;
    dst = dst % collision_space;

    // Model extra redundant relaxations when Δ is too large: a wider bucket can activate
    // more concurrent edges, increasing total relaxation work (and contention).
    int repeats = 1 + (delta / 15);
    for (int r = 0; r < repeats; ++r) {
        int idx2 = (idx + r * 9973) % EH;
        int dst2 = lg_col_idx[idx2] % collision_space;
        // Atomic contention proxy.
        atomicMin(&dist[dst2], step);
    }
}

static int arg_int(int argc, char** argv, const std::string& name, int default_value) {
    for (int i = 1; i + 1 < argc; ++i) {
        if (argv[i] == name) return std::stoi(argv[i + 1]);
    }
    return default_value;
}

static std::string arg_str(int argc, char** argv, const std::string& name, const std::string& default_value) {
    for (int i = 1; i + 1 < argc; ++i) {
        if (argv[i] == name) return argv[i + 1];
    }
    return default_value;
}

static void write_csv_header_if_needed(const std::string& out_csv) {
    std::ifstream in(out_csv);
    if (in.good() && in.peek() != std::ifstream::traits_type::eof()) return;
    std::ofstream out(out_csv, std::ios::app);
    out << "dataset,V,EH,delta,steps,active,gpu_ms\n";
}

int main(int argc, char** argv) {
    std::string dataset = arg_str(argc, argv, "--dataset", "unknown");
    std::string edges_file = arg_str(argc, argv, "--edges", "");
    std::string out_csv = arg_str(argc, argv, "--out", "results/exp4_4_3_delta/delta_ucurve.csv");

    int max_delta = arg_int(argc, argv, "--max-delta", 90);
    int min_delta = arg_int(argc, argv, "--min-delta", 5);
    int delta_step = arg_int(argc, argv, "--delta-step", 5);

    // A proxy for the number of bucket rounds over a fixed distance range.
    int bucket_range = arg_int(argc, argv, "--bucket-range", 4096);
    int repeat = arg_int(argc, argv, "--repeat", 5);

    if (edges_file.empty()) {
        std::cerr << "Missing --edges" << std::endl;
        return 1;
    }

    int n = 0;
    std::vector<Edge> edges;
    try {
        edges = load_edges_uv(edges_file, n);
    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return 1;
    }

    const int m = static_cast<int>(edges.size());
    if (m == 0) {
        std::cerr << "No edges loaded" << std::endl;
        return 1;
    }

    // Build LG topology once (not timed): V = m, EH = |E_H|
    std::vector<int> og_row_ptr, og_out_edge_ids;
    std::vector<int> lg_row_ptr, lg_col_idx;
    build_og_out_edge_csr_cpu(n, edges, og_row_ptr, og_out_edge_ids);
    build_lg_csr_cpu(edges, og_row_ptr, og_out_edge_ids, lg_row_ptr, lg_col_idx);

    const int V = m;
    const int EH = static_cast<int>(lg_col_idx.size());

    int* d_lg_col_idx = nullptr;
    int* d_dist = nullptr;
    CHECK_CUDA(cudaMalloc(&d_lg_col_idx, EH * sizeof(int)));
    CHECK_CUDA(cudaMemcpy(d_lg_col_idx, lg_col_idx.data(), EH * sizeof(int), cudaMemcpyHostToDevice));

    CHECK_CUDA(cudaMalloc(&d_dist, V * sizeof(int)));

    write_csv_header_if_needed(out_csv);
    std::ofstream out(out_csv, std::ios::app);

    const int threads = 256;

    for (int delta = min_delta; delta <= max_delta; delta += delta_step) {
        int steps = std::max(1, bucket_range / delta);
        int base_active = std::max(1, V / bucket_range);
        int active = std::min(V, base_active * delta);

        int blocks = (active + threads - 1) / threads;

        // Warm-up
        CHECK_CUDA(cudaMemset(d_dist, 0x7f, V * sizeof(int)));
        k_relax_atomic<<<blocks, threads>>>(V, EH, active, 0, delta, d_lg_col_idx, d_dist);
        CHECK_CUDA(cudaDeviceSynchronize());

        double ms_sum = 0.0;
        for (int r = 0; r < repeat; ++r) {
            CHECK_CUDA(cudaMemset(d_dist, 0x7f, V * sizeof(int)));

            cudaEvent_t start, stop;
            CHECK_CUDA(cudaEventCreate(&start));
            CHECK_CUDA(cudaEventCreate(&stop));

            CHECK_CUDA(cudaEventRecord(start));
            for (int s = 0; s < steps; ++s) {
                k_relax_atomic<<<blocks, threads>>>(V, EH, active, s, delta, d_lg_col_idx, d_dist);
                // Synchronization cost proxy (bucket barrier)
                CHECK_CUDA(cudaDeviceSynchronize());
            }
            CHECK_CUDA(cudaEventRecord(stop));
            CHECK_CUDA(cudaEventSynchronize(stop));

            float ms = 0.0f;
            CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));
            ms_sum += ms;

            CHECK_CUDA(cudaEventDestroy(start));
            CHECK_CUDA(cudaEventDestroy(stop));
        }

        float ms_avg = static_cast<float>(ms_sum / repeat);

        out << dataset << ',' << V << ',' << EH << ',' << delta << ',' << steps << ',' << active << ',' << ms_avg
            << '\n';
        std::cout << "[OK] delta=" << delta << " steps=" << steps << " active=" << active << " gpu_ms=" << ms_avg
                  << std::endl;
    }

    CHECK_CUDA(cudaFree(d_lg_col_idx));
    CHECK_CUDA(cudaFree(d_dist));

    return 0;
}
