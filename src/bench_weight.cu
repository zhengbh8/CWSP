#include <cuda_runtime.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
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
    float w;
};

static std::vector<Edge> load_edges(const std::string& edges_file, int& n_out) {
    std::ifstream in(edges_file);
    if (!in) {
        throw std::runtime_error("Cannot open edges file: " + edges_file);
    }

    std::vector<Edge> edges;
    edges.reserve(1 << 20);

    std::string line;
    int max_node = -1;
    while (std::getline(in, line)) {
        if (line.empty() || line[0] == '#') continue;
        std::stringstream ss(line);
        int u = -1, v = -1;
        float w = 0.0f;
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

static void build_lg_src_cpu(const std::vector<int>& lg_row_ptr, std::vector<int>& lg_src) {
    const int m = static_cast<int>(lg_row_ptr.size()) - 1;
    const int eh = lg_row_ptr[m];
    lg_src.resize(eh);
    for (int e1 = 0; e1 < m; ++e1) {
        int begin = lg_row_ptr[e1];
        int end = lg_row_ptr[e1 + 1];
        for (int t = begin; t < end; ++t) {
            lg_src[t] = e1;
        }
    }
}

static int infer_grid_N(int n) {
    int N = static_cast<int>(std::llround(std::sqrt(static_cast<double>(n))));
    if (N <= 0 || N * N != n) {
        return -1;
    }
    return N;
}

static inline int dir4(int a, int b, int N) {
    int ar = a / N, ac = a % N;
    int br = b / N, bc = b % N;
    if (br == ar - 1 && bc == ac) return 0; // N
    if (br == ar && bc == ac + 1) return 1; // E
    if (br == ar + 1 && bc == ac) return 2; // S
    if (br == ar && bc == ac - 1) return 3; // W
    return -1;
}

static inline float penalty_from_dirs(int in_dir, int out_dir) {
    // Same as scripts/generate_grid.py
    constexpr float P_STRAIGHT = 0.0f;
    constexpr float P_RIGHT = 2.0f;
    constexpr float P_LEFT = 5.0f;
    constexpr float P_UTURN = 100.0f;

    int diff = (out_dir - in_dir) & 3;
    if (diff == 0) return P_STRAIGHT;
    if (diff == 1) return P_RIGHT;
    if (diff == 2) return P_UTURN;
    return P_LEFT;
}

static double bench_cpu_once(
    int N,
    const std::vector<int>& edge_u,
    const std::vector<int>& edge_v,
    const std::vector<float>& edge_w,
    const std::vector<int>& lg_src,
    const std::vector<int>& lg_dst,
    std::vector<float>& out_weights) {

    const int eh = static_cast<int>(lg_dst.size());
    out_weights.resize(eh);

    auto t0 = std::chrono::steady_clock::now();
    for (int t = 0; t < eh; ++t) {
        int e1 = lg_src[t];
        int e2 = lg_dst[t];
        int u = edge_u[e1];
        int v = edge_v[e1];
        int w = edge_v[e2];

        int in_dir = dir4(u, v, N);
        int out_dir = dir4(v, w, N);
        float pen = penalty_from_dirs(in_dir, out_dir);
        out_weights[t] = edge_w[e2] + pen;
    }
    auto t1 = std::chrono::steady_clock::now();

    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

__global__ void k_weight_naive(int eh, int N, const int* __restrict__ edge_u, const int* __restrict__ edge_v,
                              const float* __restrict__ edge_w, const int* __restrict__ lg_src,
                              const int* __restrict__ lg_dst, float* __restrict__ out_w) {
    int t = blockIdx.x * blockDim.x + threadIdx.x;
    if (t >= eh) return;

    int e1 = lg_src[t];
    int e2 = lg_dst[t];
    int u = edge_u[e1];
    int v = edge_v[e1];
    int w = edge_v[e2];

    // dir4 with branching
    int ur = u / N, uc = u - ur * N;
    int vr = v / N, vc = v - vr * N;
    int wr = w / N, wc = w - wr * N;

    int in_dir = -1;
    if (vr == ur - 1 && vc == uc)
        in_dir = 0;
    else if (vr == ur && vc == uc + 1)
        in_dir = 1;
    else if (vr == ur + 1 && vc == uc)
        in_dir = 2;
    else if (vr == ur && vc == uc - 1)
        in_dir = 3;

    int out_dir = -1;
    if (wr == vr - 1 && wc == vc)
        out_dir = 0;
    else if (wr == vr && wc == vc + 1)
        out_dir = 1;
    else if (wr == vr + 1 && wc == vc)
        out_dir = 2;
    else if (wr == vr && wc == vc - 1)
        out_dir = 3;

    int diff = (out_dir - in_dir) & 3;

    float pen = 0.0f;
    // Divergent branch
    switch (diff) {
        case 0:
            pen = 0.0f;
            break;
        case 1:
            pen = 2.0f;
            break;
        case 2:
            pen = 100.0f;
            break;
        default:
            pen = 5.0f;
            break;
    }

    out_w[t] = edge_w[e2] + pen;
}

__global__ void k_weight_simt(int eh, int N, const int* __restrict__ edge_u, const int* __restrict__ edge_v,
                             const float* __restrict__ edge_w, const int* __restrict__ lg_src,
                             const int* __restrict__ lg_dst, float* __restrict__ out_w) {
    int t = blockIdx.x * blockDim.x + threadIdx.x;
    if (t >= eh) return;

    int e1 = lg_src[t];
    int e2 = lg_dst[t];
    int u = edge_u[e1];
    int v = edge_v[e1];
    int w = edge_v[e2];

    int ur = u / N, uc = u - ur * N;
    int vr = v / N, vc = v - vr * N;
    int wr = w / N, wc = w - wr * N;

    // dir4 computed with minimal branching (still some compares, but avoid penalty branch)
    int in_dir = (vr == ur - 1 && vc == uc) ? 0
               : (vr == ur && vc == uc + 1) ? 1
               : (vr == ur + 1 && vc == uc) ? 2
               : 3;

    int out_dir = (wr == vr - 1 && wc == vc) ? 0
                : (wr == vr && wc == vc + 1) ? 1
                : (wr == vr + 1 && wc == vc) ? 2
                : 3;

    int diff = (out_dir - in_dir) & 3;
    // Predication / lookup
    float p0 = 0.0f, p1 = 2.0f, p2 = 100.0f, p3 = 5.0f;
    float pen = (diff == 0) * p0 + (diff == 1) * p1 + (diff == 2) * p2 + (diff == 3) * p3;

    out_w[t] = edge_w[e2] + pen;
}

static float bench_gpu_kernel_naive(
    int eh,
    int N,
    const std::vector<int>& h_edge_u,
    const std::vector<int>& h_edge_v,
    const std::vector<float>& h_edge_w,
    const std::vector<int>& h_lg_src,
    const std::vector<int>& h_lg_dst) {

    int m = static_cast<int>(h_edge_u.size());

    int* d_edge_u = nullptr;
    int* d_edge_v = nullptr;
    float* d_edge_w = nullptr;
    int* d_lg_src = nullptr;
    int* d_lg_dst = nullptr;
    float* d_out = nullptr;

    CHECK_CUDA(cudaMalloc(&d_edge_u, m * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_edge_v, m * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_edge_w, m * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&d_lg_src, eh * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_lg_dst, eh * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_out, eh * sizeof(float)));

    CHECK_CUDA(cudaMemcpy(d_edge_u, h_edge_u.data(), m * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_edge_v, h_edge_v.data(), m * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_edge_w, h_edge_w.data(), m * sizeof(float), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_lg_src, h_lg_src.data(), eh * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_lg_dst, h_lg_dst.data(), eh * sizeof(int), cudaMemcpyHostToDevice));

    const int threads = 256;
    const int blocks = (eh + threads - 1) / threads;

    // Warm-up
    k_weight_naive<<<blocks, threads>>>(eh, N, d_edge_u, d_edge_v, d_edge_w, d_lg_src, d_lg_dst, d_out);
    CHECK_CUDA(cudaDeviceSynchronize());

    cudaEvent_t start, stop;
    CHECK_CUDA(cudaEventCreate(&start));
    CHECK_CUDA(cudaEventCreate(&stop));

    CHECK_CUDA(cudaEventRecord(start));
    k_weight_naive<<<blocks, threads>>>(eh, N, d_edge_u, d_edge_v, d_edge_w, d_lg_src, d_lg_dst, d_out);
    CHECK_CUDA(cudaEventRecord(stop));
    CHECK_CUDA(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));

    CHECK_CUDA(cudaEventDestroy(start));
    CHECK_CUDA(cudaEventDestroy(stop));

    CHECK_CUDA(cudaFree(d_edge_u));
    CHECK_CUDA(cudaFree(d_edge_v));
    CHECK_CUDA(cudaFree(d_edge_w));
    CHECK_CUDA(cudaFree(d_lg_src));
    CHECK_CUDA(cudaFree(d_lg_dst));
    CHECK_CUDA(cudaFree(d_out));

    return ms;
}

static float bench_gpu_kernel_simt(
    int eh,
    int N,
    const std::vector<int>& h_edge_u,
    const std::vector<int>& h_edge_v,
    const std::vector<float>& h_edge_w,
    const std::vector<int>& h_lg_src,
    const std::vector<int>& h_lg_dst) {

    int m = static_cast<int>(h_edge_u.size());

    int* d_edge_u = nullptr;
    int* d_edge_v = nullptr;
    float* d_edge_w = nullptr;
    int* d_lg_src = nullptr;
    int* d_lg_dst = nullptr;
    float* d_out = nullptr;

    CHECK_CUDA(cudaMalloc(&d_edge_u, m * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_edge_v, m * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_edge_w, m * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&d_lg_src, eh * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_lg_dst, eh * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_out, eh * sizeof(float)));

    CHECK_CUDA(cudaMemcpy(d_edge_u, h_edge_u.data(), m * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_edge_v, h_edge_v.data(), m * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_edge_w, h_edge_w.data(), m * sizeof(float), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_lg_src, h_lg_src.data(), eh * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_lg_dst, h_lg_dst.data(), eh * sizeof(int), cudaMemcpyHostToDevice));

    const int threads = 256;
    const int blocks = (eh + threads - 1) / threads;

    // Warm-up
    k_weight_simt<<<blocks, threads>>>(eh, N, d_edge_u, d_edge_v, d_edge_w, d_lg_src, d_lg_dst, d_out);
    CHECK_CUDA(cudaDeviceSynchronize());

    cudaEvent_t start, stop;
    CHECK_CUDA(cudaEventCreate(&start));
    CHECK_CUDA(cudaEventCreate(&stop));

    CHECK_CUDA(cudaEventRecord(start));
    k_weight_simt<<<blocks, threads>>>(eh, N, d_edge_u, d_edge_v, d_edge_w, d_lg_src, d_lg_dst, d_out);
    CHECK_CUDA(cudaEventRecord(stop));
    CHECK_CUDA(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));

    CHECK_CUDA(cudaEventDestroy(start));
    CHECK_CUDA(cudaEventDestroy(stop));

    CHECK_CUDA(cudaFree(d_edge_u));
    CHECK_CUDA(cudaFree(d_edge_v));
    CHECK_CUDA(cudaFree(d_edge_w));
    CHECK_CUDA(cudaFree(d_lg_src));
    CHECK_CUDA(cudaFree(d_lg_dst));
    CHECK_CUDA(cudaFree(d_out));

    return ms;
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
    out << "dataset,eh,repeat,cpu_ms,gpu_naive_ms,gpu_simt_ms,speedup\n";
}

int main(int argc, char** argv) {
    std::string dataset = arg_str(argc, argv, "--dataset", "unknown");
    std::string edges_file = arg_str(argc, argv, "--edges", "");
    std::string out_csv = arg_str(argc, argv, "--out", "results/exp4_4_2_weight/weight_speedup.csv");
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

    int N = infer_grid_N(n);
    if (N < 0) {
        std::cerr << "This benchmark expects a grid dataset with n=N^2. Got n=" << n << std::endl;
        return 2;
    }

    const int m = static_cast<int>(edges.size());
    if (m == 0) {
        std::cerr << "No edges loaded." << std::endl;
        return 1;
    }

    // Prepare arrays
    std::vector<int> edge_u(m), edge_v(m);
    std::vector<float> edge_w(m);
    for (int i = 0; i < m; ++i) {
        edge_u[i] = edges[i].u;
        edge_v[i] = edges[i].v;
        edge_w[i] = edges[i].w;
    }

    // Build topology once (NOT timed)
    std::vector<int> og_row_ptr, og_out_edge_ids;
    build_og_out_edge_csr_cpu(n, edges, og_row_ptr, og_out_edge_ids);

    std::vector<int> lg_row_ptr, lg_col_idx, lg_src;
    build_lg_csr_cpu(edges, og_row_ptr, og_out_edge_ids, lg_row_ptr, lg_col_idx);
    build_lg_src_cpu(lg_row_ptr, lg_src);

    const int eh = static_cast<int>(lg_col_idx.size());

    // Timed runs
    double cpu_sum = 0.0;
    double gpu_naive_sum = 0.0;
    double gpu_simt_sum = 0.0;

    std::vector<float> tmp_cpu;

    // Warm-up CPU once
    (void)bench_cpu_once(N, edge_u, edge_v, edge_w, lg_src, lg_col_idx, tmp_cpu);

    for (int r = 0; r < repeat; ++r) {
        cpu_sum += bench_cpu_once(N, edge_u, edge_v, edge_w, lg_src, lg_col_idx, tmp_cpu);
        gpu_naive_sum += bench_gpu_kernel_naive(eh, N, edge_u, edge_v, edge_w, lg_src, lg_col_idx);
        gpu_simt_sum += bench_gpu_kernel_simt(eh, N, edge_u, edge_v, edge_w, lg_src, lg_col_idx);
    }

    double cpu_ms = cpu_sum / repeat;
    double gpu_naive_ms = gpu_naive_sum / repeat;
    double gpu_simt_ms = gpu_simt_sum / repeat;
    double speedup = cpu_ms / gpu_simt_ms;

    write_csv_header_if_needed(out_csv);
    std::ofstream out(out_csv, std::ios::app);
    out << dataset << ',' << eh << ',' << repeat << ',' << cpu_ms << ',' << gpu_naive_ms << ',' << gpu_simt_ms << ','
        << speedup << '\n';

    std::cout << "[OK] " << dataset << " eh=" << eh << " cpu_ms=" << cpu_ms << " gpu_naive_ms=" << gpu_naive_ms
              << " gpu_simt_ms=" << gpu_simt_ms << " speedup=" << speedup << "x" << std::endl;

    return 0;
}
