#include <cuda_runtime.h>
#include <cub/cub.cuh>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
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

static void write_csv_header_if_needed(const std::string& out_csv) {
    std::ifstream in(out_csv);
    if (in.good() && in.peek() != std::ifstream::traits_type::eof()) {
        return;
    }
    std::ofstream out(out_csv, std::ios::app);
    out << "dataset,n,m,lg_nodes,lg_edges,repeat,cpu_ms,gpu_ms,speedup\n";
}

static std::vector<Edge> load_edges(const std::string& edges_file, int& num_nodes_out) {
    std::ifstream in(edges_file);
    if (!in) {
        throw std::runtime_error("Cannot open edges file: " + edges_file);
    }

    std::vector<Edge> edges;
    edges.reserve(1 << 20);

    std::string line;
    int max_node = -1;
    while (std::getline(in, line)) {
        if (line.empty() || line[0] == '#') {
            continue;
        }
        std::stringstream ss(line);
        int u = -1, v = -1;
        double w = 0.0;
        if (!(ss >> u >> v >> w)) {
            continue;
        }
        edges.push_back({u, v});
        max_node = std::max(max_node, std::max(u, v));
    }

    num_nodes_out = max_node + 1;
    return edges;
}

// Build original graph outgoing-edge-id CSR on CPU
static void build_og_out_edge_csr_cpu(
    int n,
    const std::vector<Edge>& edges,
    std::vector<int>& og_row_ptr,
    std::vector<int>& og_out_edge_ids) {

    const int m = static_cast<int>(edges.size());
    og_row_ptr.assign(n + 1, 0);
    for (int e = 0; e < m; ++e) {
        int u = edges[e].u;
        og_row_ptr[u + 1]++;
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

// CPU line-graph topology CSR build: given original CSR and edge_v
static void build_lg_topology_csr_cpu(
    int n,
    const std::vector<Edge>& edges,
    const std::vector<int>& og_row_ptr,
    const std::vector<int>& og_out_edge_ids,
    std::vector<int>& lg_row_ptr,
    std::vector<int>& lg_col_idx) {

    (void)n;
    const int m = static_cast<int>(edges.size());

    // counts[e1] = outdeg(v)
    std::vector<int> counts(m);
    for (int e1 = 0; e1 < m; ++e1) {
        int v = edges[e1].v;
        counts[e1] = og_row_ptr[v + 1] - og_row_ptr[v];
    }

    lg_row_ptr.assign(m + 1, 0);
    for (int i = 0; i < m; ++i) {
        lg_row_ptr[i + 1] = lg_row_ptr[i] + counts[i];
    }

    const int lg_m = lg_row_ptr[m];
    lg_col_idx.resize(lg_m);

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

__global__ void k_count_lg_edges(int m, const int* __restrict__ d_edge_v, const int* __restrict__ d_og_row_ptr,
                                int* __restrict__ d_lg_counts) {
    int e1 = blockIdx.x * blockDim.x + threadIdx.x;
    if (e1 >= m) return;
    int v = d_edge_v[e1];
    d_lg_counts[e1] = d_og_row_ptr[v + 1] - d_og_row_ptr[v];
}

__global__ void k_fill_lg_col_idx(int m, const int* __restrict__ d_edge_v, const int* __restrict__ d_og_row_ptr,
                                 const int* __restrict__ d_og_out_edge_ids, const int* __restrict__ d_lg_row_ptr,
                                 int* __restrict__ d_lg_col_idx) {
    int e1 = blockIdx.x * blockDim.x + threadIdx.x;
    if (e1 >= m) return;

    int v = d_edge_v[e1];
    int og_begin = d_og_row_ptr[v];
    int og_end = d_og_row_ptr[v + 1];
    int base = d_lg_row_ptr[e1];
    for (int i = 0; i < (og_end - og_begin); ++i) {
        d_lg_col_idx[base + i] = d_og_out_edge_ids[og_begin + i];
    }
}

static double bench_cpu_once(
    int n,
    const std::vector<Edge>& edges,
    const std::vector<int>& og_row_ptr,
    const std::vector<int>& og_out_edge_ids,
    int& lg_nodes_out,
    int& lg_edges_out) {

    std::vector<int> lg_row_ptr;
    std::vector<int> lg_col_idx;

    auto t0 = std::chrono::steady_clock::now();
    build_lg_topology_csr_cpu(n, edges, og_row_ptr, og_out_edge_ids, lg_row_ptr, lg_col_idx);
    auto t1 = std::chrono::steady_clock::now();

    lg_nodes_out = static_cast<int>(edges.size());
    lg_edges_out = static_cast<int>(lg_col_idx.size());

    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

static float bench_gpu_once(
    int n,
    int m,
    const std::vector<int>& h_edge_v,
    const std::vector<int>& h_og_row_ptr,
    const std::vector<int>& h_og_out_edge_ids,
    int& lg_edges_out) {

    (void)n;

    int* d_edge_v = nullptr;
    int* d_og_row_ptr = nullptr;
    int* d_og_out_edge_ids = nullptr;
    int* d_lg_counts = nullptr;
    int* d_lg_row_ptr = nullptr;

    CHECK_CUDA(cudaMalloc(&d_edge_v, m * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_og_row_ptr, (static_cast<int>(h_og_row_ptr.size())) * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_og_out_edge_ids, (static_cast<int>(h_og_out_edge_ids.size())) * sizeof(int)));

    CHECK_CUDA(cudaMemcpy(d_edge_v, h_edge_v.data(), m * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_og_row_ptr, h_og_row_ptr.data(), h_og_row_ptr.size() * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_og_out_edge_ids, h_og_out_edge_ids.data(), h_og_out_edge_ids.size() * sizeof(int), cudaMemcpyHostToDevice));

    CHECK_CUDA(cudaMalloc(&d_lg_counts, m * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_lg_row_ptr, (m + 1) * sizeof(int)));

    cudaEvent_t start, stop;
    CHECK_CUDA(cudaEventCreate(&start));
    CHECK_CUDA(cudaEventCreate(&stop));

    const int threads = 256;
    const int blocks = (m + threads - 1) / threads;

    // Warm-up
    k_count_lg_edges<<<blocks, threads>>>(m, d_edge_v, d_og_row_ptr, d_lg_counts);
    CHECK_CUDA(cudaDeviceSynchronize());

    CHECK_CUDA(cudaEventRecord(start));

    // 1) Count
    k_count_lg_edges<<<blocks, threads>>>(m, d_edge_v, d_og_row_ptr, d_lg_counts);

    // 2) Exclusive scan counts -> row_ptr[0..m-1] (offsets)
    //    Then set row_ptr[m] = row_ptr[m-1] + counts[m-1] (total edges)
    size_t temp_bytes = 0;
    CHECK_CUDA(cub::DeviceScan::ExclusiveSum(nullptr, temp_bytes, d_lg_counts, d_lg_row_ptr, m));
    void* d_temp = nullptr;
    CHECK_CUDA(cudaMalloc(&d_temp, temp_bytes));
    CHECK_CUDA(cub::DeviceScan::ExclusiveSum(d_temp, temp_bytes, d_lg_counts, d_lg_row_ptr, m));
    CHECK_CUDA(cudaFree(d_temp));

    int last_offset = 0;
    int last_count = 0;
    CHECK_CUDA(cudaMemcpy(&last_offset, d_lg_row_ptr + (m - 1), sizeof(int), cudaMemcpyDeviceToHost));
    CHECK_CUDA(cudaMemcpy(&last_count, d_lg_counts + (m - 1), sizeof(int), cudaMemcpyDeviceToHost));
    lg_edges_out = last_offset + last_count;
    CHECK_CUDA(cudaMemcpy(d_lg_row_ptr + m, &lg_edges_out, sizeof(int), cudaMemcpyHostToDevice));

    // 3) Allocate col_idx based on lg_row_ptr[m]
    int* d_lg_col_idx = nullptr;
    CHECK_CUDA(cudaMalloc(&d_lg_col_idx, lg_edges_out * sizeof(int)));

    // 4) Fill
    k_fill_lg_col_idx<<<blocks, threads>>>(m, d_edge_v, d_og_row_ptr, d_og_out_edge_ids, d_lg_row_ptr, d_lg_col_idx);

    CHECK_CUDA(cudaEventRecord(stop));
    CHECK_CUDA(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));

    CHECK_CUDA(cudaEventDestroy(start));
    CHECK_CUDA(cudaEventDestroy(stop));

    CHECK_CUDA(cudaFree(d_edge_v));
    CHECK_CUDA(cudaFree(d_og_row_ptr));
    CHECK_CUDA(cudaFree(d_og_out_edge_ids));
    CHECK_CUDA(cudaFree(d_lg_counts));
    CHECK_CUDA(cudaFree(d_lg_row_ptr));
    CHECK_CUDA(cudaFree(d_lg_col_idx));

    return ms;
}

static int arg_int(int argc, char** argv, const std::string& name, int default_value) {
    for (int i = 1; i + 1 < argc; ++i) {
        if (argv[i] == name) {
            return std::stoi(argv[i + 1]);
        }
    }
    return default_value;
}

static std::string arg_str(int argc, char** argv, const std::string& name, const std::string& default_value) {
    for (int i = 1; i + 1 < argc; ++i) {
        if (argv[i] == name) {
            return argv[i + 1];
        }
    }
    return default_value;
}

int main(int argc, char** argv) {
    if (argc < 4) {
        std::cerr << "Usage: " << argv[0]
                  << " --dataset <name> --edges <edges_file> [--repeat R] --out <csv>\n";
        return 1;
    }

    std::string dataset = arg_str(argc, argv, "--dataset", "unknown");
    std::string edges_file = arg_str(argc, argv, "--edges", "");
    std::string out_csv = arg_str(argc, argv, "--out", "results/exp4_4_1_topology/topology.csv");
    int repeat = arg_int(argc, argv, "--repeat", 10);

    if (edges_file.empty()) {
        std::cerr << "Missing --edges" << std::endl;
        return 1;
    }

    int n = 0;
    std::vector<Edge> edges;
    try {
        edges = load_edges(edges_file, n);
    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return 1;
    }

    const int m = static_cast<int>(edges.size());
    if (m == 0) {
        std::cerr << "No edges loaded from " << edges_file << std::endl;
        return 1;
    }

    // Build original CSR once on CPU (this stage is treated as precondition for topology rebuild)
    std::vector<int> og_row_ptr;
    std::vector<int> og_out_edge_ids;
    build_og_out_edge_csr_cpu(n, edges, og_row_ptr, og_out_edge_ids);

    // Prepare edge_v array
    std::vector<int> edge_v(m);
    for (int i = 0; i < m; ++i) {
        edge_v[i] = edges[i].v;
    }

    // Repeat and average
    double cpu_sum = 0.0;
    float gpu_sum = 0.0f;
    int lg_nodes = 0;
    int lg_edges_cpu = 0;
    int lg_edges_gpu = 0;

    // One dry run for correctness sanity (counts should match)
    {
        std::vector<int> lg_row_ptr;
        std::vector<int> lg_col_idx;
        build_lg_topology_csr_cpu(n, edges, og_row_ptr, og_out_edge_ids, lg_row_ptr, lg_col_idx);
        lg_edges_cpu = static_cast<int>(lg_col_idx.size());
        lg_nodes = m;
    }

    // GPU dry run
    (void)bench_gpu_once(n, m, edge_v, og_row_ptr, og_out_edge_ids, lg_edges_gpu);
    if (lg_edges_gpu != lg_edges_cpu) {
        std::cerr << "[ERROR] CPU/GPU lg_edges mismatch: cpu=" << lg_edges_cpu << " gpu=" << lg_edges_gpu << std::endl;
        return 2;
    }

    for (int r = 0; r < repeat; ++r) {
        cpu_sum += bench_cpu_once(n, edges, og_row_ptr, og_out_edge_ids, lg_nodes, lg_edges_cpu);
        gpu_sum += bench_gpu_once(n, m, edge_v, og_row_ptr, og_out_edge_ids, lg_edges_gpu);
    }

    const double cpu_ms = cpu_sum / repeat;
    const double gpu_ms = static_cast<double>(gpu_sum) / repeat;
    const double speedup = cpu_ms / gpu_ms;

    write_csv_header_if_needed(out_csv);
    std::ofstream out(out_csv, std::ios::app);
    out << dataset << ',' << n << ',' << m << ',' << lg_nodes << ',' << lg_edges_cpu << ',' << repeat << ',' << cpu_ms
        << ',' << gpu_ms << ',' << speedup << '\n';

    std::cout << "[OK] " << dataset << " n=" << n << " m=" << m << " lg_edges=" << lg_edges_cpu << " cpu_ms="
              << cpu_ms << " gpu_ms=" << gpu_ms << " speedup=" << speedup << "x" << std::endl;

    return 0;
}
