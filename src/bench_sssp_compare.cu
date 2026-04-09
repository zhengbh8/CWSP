#include <cuda_runtime.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <queue>
#include <sstream>
#include <string>
#include <tuple>
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
    int w;
};

static std::vector<Edge> load_edges_uvw(const std::string& edges_file, int& n_out) {
    std::ifstream in(edges_file);
    if (!in) throw std::runtime_error("Cannot open edges file: " + edges_file);

    std::vector<Edge> edges;
    edges.reserve(1 << 20);

    std::string line;
    int max_node = -1;
    while (std::getline(in, line)) {
        if (line.empty() || line[0] == '#') continue;
        std::stringstream ss(line);
        int u = -1, v = -1, w = 1;
        if (!(ss >> u >> v >> w)) continue;
        edges.push_back({u, v, w});
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

enum Dir : int { DIR_UNKNOWN = 0, DIR_N = 1, DIR_E = 2, DIR_S = 3, DIR_W = 4 };

static Dir dir_from_uv(int u, int v, int grid_n) {
    int diff = v - u;
    if (diff == 1) return DIR_E;
    if (diff == -1) return DIR_W;
    if (diff == grid_n) return DIR_S;
    if (diff == -grid_n) return DIR_N;
    return DIR_UNKNOWN;
}

static int infer_grid_n(int num_nodes) {
    int n = static_cast<int>(std::llround(std::sqrt(static_cast<double>(num_nodes))));
    if (n <= 0 || n * n != num_nodes) return -1;
    return n;
}

static void build_lg_csr_and_weights_for_grid(
    int grid_n,
    const std::vector<Edge>& edges,
    const std::vector<int>& og_row_ptr,
    const std::vector<int>& og_out_edge_ids,
    int turn_penalty,
    std::vector<int>& lg_row_ptr,
    std::vector<int>& lg_col_idx,
    std::vector<int>& lg_w) {

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
    lg_w.resize(eh);

    for (int e1 = 0; e1 < m; ++e1) {
        int u1 = edges[e1].u;
        int v1 = edges[e1].v;
        Dir d1 = dir_from_uv(u1, v1, grid_n);

        int begin = og_row_ptr[v1];
        int end = og_row_ptr[v1 + 1];
        int base = lg_row_ptr[e1];
        for (int k = 0; k < (end - begin); ++k) {
            int e2 = og_out_edge_ids[begin + k];
            int u2 = edges[e2].u;
            int v2 = edges[e2].v;
            Dir d2 = dir_from_uv(u2, v2, grid_n);

            int penalty = (d1 == DIR_UNKNOWN || d2 == DIR_UNKNOWN || d1 != d2) ? turn_penalty : 0;
            lg_col_idx[base + k] = e2;
            lg_w[base + k] = edges[e2].w + penalty;
        }
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
    out << "dataset,grid_n,V,EH,delta,turn_penalty,cpu_ms,gpu_ms,speedup\n";
}

static double run_cpu_dijkstra_ms(const std::vector<int>& row_ptr, const std::vector<int>& col_idx,
                                 const std::vector<int>& w, int src, int repeat) {
    const int V = static_cast<int>(row_ptr.size()) - 1;
    const int INF = std::numeric_limits<int>::max() / 4;

    double total_ms = 0.0;
    for (int r = 0; r < repeat; ++r) {
        std::vector<int> dist(V, INF);
        std::vector<uint8_t> vis(V, 0);
        using P = std::pair<int, int>;
        std::priority_queue<P, std::vector<P>, std::greater<P>> pq;

        auto t1 = std::chrono::high_resolution_clock::now();
        dist[src] = 0;
        pq.push({0, src});
        while (!pq.empty()) {
            auto [du, u] = pq.top();
            pq.pop();
            if (vis[u]) continue;
            vis[u] = 1;
            if (du != dist[u]) continue;

            int begin = row_ptr[u];
            int end = row_ptr[u + 1];
            for (int e = begin; e < end; ++e) {
                int v = col_idx[e];
                int nd = du + w[e];
                if (nd < dist[v]) {
                    dist[v] = nd;
                    pq.push({nd, v});
                }
            }
        }
        auto t2 = std::chrono::high_resolution_clock::now();
        total_ms += std::chrono::duration_cast<std::chrono::microseconds>(t2 - t1).count() / 1000.0;
    }

    return total_ms / repeat;
}

__global__ void k_init(int V, int src, int inf, int* dist, uint8_t* processed) {
    int t = blockIdx.x * blockDim.x + threadIdx.x;
    if (t >= V) return;
    dist[t] = (t == src) ? 0 : inf;
    processed[t] = 0;
}

__global__ void k_relax_bucket(int V, const int* __restrict__ row_ptr, const int* __restrict__ col_idx,
                              const int* __restrict__ w, int* __restrict__ dist,
                              const uint8_t* __restrict__ processed, int bucket, int delta, int inf, int* changed) {
    int u = blockIdx.x * blockDim.x + threadIdx.x;
    if (u >= V) return;
    if (processed[u]) return;

    int du = dist[u];
    if (du >= inf) return;

    int lo = bucket * delta;
    int hi = lo + delta;
    if (du < lo || du >= hi) return;

    int begin = row_ptr[u];
    int end = row_ptr[u + 1];
    for (int e = begin; e < end; ++e) {
        int v = col_idx[e];
        int nd = du + w[e];
        int old = atomicMin(&dist[v], nd);
        if (nd < old && nd < hi) {
            atomicExch(changed, 1);
        }
    }
}

__global__ void k_mark_processed_bucket(int V, const int* __restrict__ dist, uint8_t* __restrict__ processed,
                                       int bucket, int delta, int inf) {
    int u = blockIdx.x * blockDim.x + threadIdx.x;
    if (u >= V) return;
    if (processed[u]) return;

    int du = dist[u];
    if (du >= inf) return;

    int lo = bucket * delta;
    int hi = lo + delta;
    if (du >= lo && du < hi) processed[u] = 1;
}

__global__ void k_any_unprocessed_finite(int V, const int* __restrict__ dist, const uint8_t* __restrict__ processed,
                                        int inf, int* any) {
    int u = blockIdx.x * blockDim.x + threadIdx.x;
    if (u >= V) return;
    if (processed[u]) return;
    if (dist[u] < inf) atomicExch(any, 1);
}

static float run_gpu_delta_stepping_ms(const std::vector<int>& row_ptr, const std::vector<int>& col_idx,
                                      const std::vector<int>& w, int src, int delta, int max_w, int repeat,
                                      int* out_last_bucket = nullptr) {
    const int V = static_cast<int>(row_ptr.size()) - 1;
    const int EH = static_cast<int>(col_idx.size());
    const int threads = 256;
    const int blocksV = (V + threads - 1) / threads;

    int* d_row_ptr = nullptr;
    int* d_col_idx = nullptr;
    int* d_w = nullptr;
    int* d_dist = nullptr;
    uint8_t* d_processed = nullptr;
    int* d_changed = nullptr;
    int* d_any = nullptr;

    CHECK_CUDA(cudaMalloc(&d_row_ptr, (V + 1) * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_col_idx, EH * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_w, EH * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_dist, V * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_processed, V * sizeof(uint8_t)));
    CHECK_CUDA(cudaMalloc(&d_changed, sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_any, sizeof(int)));

    CHECK_CUDA(cudaMemcpy(d_row_ptr, row_ptr.data(), (V + 1) * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_col_idx, col_idx.data(), EH * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_w, w.data(), EH * sizeof(int), cudaMemcpyHostToDevice));

    const int INF = std::numeric_limits<int>::max() / 4;

    // Very rough upper bound on buckets: (diameter * max_w) / delta.
    // For N x N grid, diameter is O(2N); use 8N as a safe guard.
    int max_buckets_guard = std::max(128, (8 * static_cast<int>(std::sqrt(static_cast<double>(V))) * max_w) / delta + 64);

    float total_ms = 0.0f;
    int last_bucket = 0;

    for (int r = 0; r < repeat; ++r) {
        k_init<<<blocksV, threads>>>(V, src, INF, d_dist, d_processed);
        CHECK_CUDA(cudaDeviceSynchronize());

        cudaEvent_t start, stop;
        CHECK_CUDA(cudaEventCreate(&start));
        CHECK_CUDA(cudaEventCreate(&stop));
        CHECK_CUDA(cudaEventRecord(start));

        int bucket = 0;
        for (; bucket < max_buckets_guard; ++bucket) {
            // Closure within bucket (all weights <= delta).
            while (true) {
                CHECK_CUDA(cudaMemset(d_changed, 0, sizeof(int)));
                k_relax_bucket<<<blocksV, threads>>>(V, d_row_ptr, d_col_idx, d_w, d_dist, d_processed, bucket, delta, INF,
                                                   d_changed);
                CHECK_CUDA(cudaDeviceSynchronize());
                int h_changed = 0;
                CHECK_CUDA(cudaMemcpy(&h_changed, d_changed, sizeof(int), cudaMemcpyDeviceToHost));
                if (!h_changed) break;
            }

            k_mark_processed_bucket<<<blocksV, threads>>>(V, d_dist, d_processed, bucket, delta, INF);
            CHECK_CUDA(cudaDeviceSynchronize());

            CHECK_CUDA(cudaMemset(d_any, 0, sizeof(int)));
            k_any_unprocessed_finite<<<blocksV, threads>>>(V, d_dist, d_processed, INF, d_any);
            CHECK_CUDA(cudaDeviceSynchronize());
            int h_any = 0;
            CHECK_CUDA(cudaMemcpy(&h_any, d_any, sizeof(int), cudaMemcpyDeviceToHost));
            if (!h_any) break;
        }
        last_bucket = bucket;

        CHECK_CUDA(cudaEventRecord(stop));
        CHECK_CUDA(cudaEventSynchronize(stop));
        float ms = 0.0f;
        CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));
        total_ms += ms;

        CHECK_CUDA(cudaEventDestroy(start));
        CHECK_CUDA(cudaEventDestroy(stop));
    }

    if (out_last_bucket) *out_last_bucket = last_bucket;

    CHECK_CUDA(cudaFree(d_row_ptr));
    CHECK_CUDA(cudaFree(d_col_idx));
    CHECK_CUDA(cudaFree(d_w));
    CHECK_CUDA(cudaFree(d_dist));
    CHECK_CUDA(cudaFree(d_processed));
    CHECK_CUDA(cudaFree(d_changed));
    CHECK_CUDA(cudaFree(d_any));

    return total_ms / repeat;
}

int main(int argc, char** argv) {
    std::string dataset = arg_str(argc, argv, "--dataset", "grid");
    std::string edges_file = arg_str(argc, argv, "--edges", "");
    std::string out_csv = arg_str(argc, argv, "--out", "results/exp4_4_3_compare/sssp_compare.csv");

    int delta = arg_int(argc, argv, "--delta", 35);
    int turn_penalty = arg_int(argc, argv, "--turn-penalty", 10);
    int repeat = arg_int(argc, argv, "--repeat", 3);

    if (edges_file.empty()) {
        std::cerr << "Missing --edges" << std::endl;
        return 1;
    }

    int n = 0;
    std::vector<Edge> edges;
    try {
        edges = load_edges_uvw(edges_file, n);
    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return 1;
    }

    const int m = static_cast<int>(edges.size());
    if (m == 0) {
        std::cerr << "No edges loaded" << std::endl;
        return 1;
    }

    int grid_n = infer_grid_n(n);
    if (grid_n <= 0) {
        std::cerr << "This benchmark expects grid_NxN node IDs (N*N nodes). Got n=" << n << std::endl;
        return 1;
    }

    // Build original out-edge CSR (not timed).
    std::vector<int> og_row_ptr, og_out_edge_ids;
    build_og_out_edge_csr_cpu(n, edges, og_row_ptr, og_out_edge_ids);

    // Build line graph CSR + weights (not timed).
    std::vector<int> lg_row_ptr, lg_col_idx, lg_w;
    build_lg_csr_and_weights_for_grid(grid_n, edges, og_row_ptr, og_out_edge_ids, turn_penalty, lg_row_ptr, lg_col_idx,
                                      lg_w);

    const int V = m;
    const int EH = static_cast<int>(lg_col_idx.size());

    int src = arg_int(argc, argv, "--src", 0);
    if (src < 0 || src >= V) src = 0;

    int max_w = 0;
    for (int ww : lg_w) max_w = std::max(max_w, ww);
    if (max_w > delta) {
        std::cerr << "Warning: max edge weight (" << max_w << ") > delta (" << delta
                  << "). This simplified GPU implementation assumes all weights <= delta." << std::endl;
    }

    std::cout << "[INFO] dataset=" << dataset << " grid_n=" << grid_n << " V=" << V << " EH=" << EH
              << " delta=" << delta << " turn_penalty=" << turn_penalty << " repeat=" << repeat << std::endl;

    // CPU Dijkstra (serial baseline).
    double cpu_ms = run_cpu_dijkstra_ms(lg_row_ptr, lg_col_idx, lg_w, src, repeat);

    // GPU delta-stepping (bucketed, weights <= delta).
    int last_bucket = 0;
    float gpu_ms = run_gpu_delta_stepping_ms(lg_row_ptr, lg_col_idx, lg_w, src, delta, max_w, repeat, &last_bucket);

    double speedup = cpu_ms / static_cast<double>(gpu_ms);

    write_csv_header_if_needed(out_csv);
    std::ofstream out(out_csv, std::ios::app);
    out << dataset << ',' << grid_n << ',' << V << ',' << EH << ',' << delta << ',' << turn_penalty << ','
        << cpu_ms << ',' << gpu_ms << ',' << speedup << '\n';

    std::cout << "[OK] CPU=" << cpu_ms << " ms, GPU=" << gpu_ms << " ms, speedup=" << speedup
              << "x, buckets~" << last_bucket << std::endl;

    return 0;
}
