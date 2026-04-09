#include <cuda_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
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
    for (int i = 0; i < n; ++i) og_row_ptr[i + 1] += og_row_ptr[i];

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
    for (int i = 0; i < m; ++i) lg_row_ptr[i + 1] = lg_row_ptr[i] + counts[i];

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
    out << "dataset,grid_n,V,EH,bytes_h2d,bytes_d2h,h2d_ms,d2h_ms,transfer_ms\n";
}

int main(int argc, char** argv) {
    std::string dataset = arg_str(argc, argv, "--dataset", "grid");
    std::string edges_file = arg_str(argc, argv, "--edges", "");
    std::string out_csv = arg_str(argc, argv, "--out", "results/exp4_4_4_overall/transfer.csv");

    int turn_penalty = arg_int(argc, argv, "--turn-penalty", 10);
    int repeat = arg_int(argc, argv, "--repeat", 5);

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

    int grid_n = infer_grid_n(n);
    if (grid_n <= 0) {
        std::cerr << "Expected grid_NxN node IDs (N*N nodes). Got n=" << n << std::endl;
        return 2;
    }

    const int m = static_cast<int>(edges.size());
    if (m == 0) {
        std::cerr << "No edges loaded" << std::endl;
        return 1;
    }

    std::vector<int> og_row_ptr, og_out_edge_ids;
    build_og_out_edge_csr_cpu(n, edges, og_row_ptr, og_out_edge_ids);

    std::vector<int> lg_row_ptr, lg_col_idx, lg_w;
    build_lg_csr_and_weights_for_grid(grid_n, edges, og_row_ptr, og_out_edge_ids, turn_penalty, lg_row_ptr, lg_col_idx,
                                      lg_w);

    const int V = m;
    const int EH = static_cast<int>(lg_col_idx.size());

    // Pinned host buffers for async copies
    int* h_row_ptr = nullptr;
    int* h_col_idx = nullptr;
    int* h_w = nullptr;
    int* h_dist = nullptr;

    CHECK_CUDA(cudaMallocHost(&h_row_ptr, (V + 1) * sizeof(int)));
    CHECK_CUDA(cudaMallocHost(&h_col_idx, EH * sizeof(int)));
    CHECK_CUDA(cudaMallocHost(&h_w, EH * sizeof(int)));
    CHECK_CUDA(cudaMallocHost(&h_dist, V * sizeof(int)));

    std::memcpy(h_row_ptr, lg_row_ptr.data(), (V + 1) * sizeof(int));
    std::memcpy(h_col_idx, lg_col_idx.data(), EH * sizeof(int));
    std::memcpy(h_w, lg_w.data(), EH * sizeof(int));

    int* d_row_ptr = nullptr;
    int* d_col_idx = nullptr;
    int* d_w = nullptr;
    int* d_dist = nullptr;

    CHECK_CUDA(cudaMalloc(&d_row_ptr, (V + 1) * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_col_idx, EH * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_w, EH * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&d_dist, V * sizeof(int)));

    cudaStream_t stream;
    CHECK_CUDA(cudaStreamCreate(&stream));

    cudaEvent_t start, stop;
    CHECK_CUDA(cudaEventCreate(&start));
    CHECK_CUDA(cudaEventCreate(&stop));

    float h2d_sum = 0.0f;
    float d2h_sum = 0.0f;

    size_t bytes_h2d = (V + 1) * sizeof(int) + EH * sizeof(int) + EH * sizeof(int);
    size_t bytes_d2h = V * sizeof(int);

    // Warm-up
    CHECK_CUDA(cudaMemcpyAsync(d_row_ptr, h_row_ptr, (V + 1) * sizeof(int), cudaMemcpyHostToDevice, stream));
    CHECK_CUDA(cudaMemcpyAsync(d_col_idx, h_col_idx, EH * sizeof(int), cudaMemcpyHostToDevice, stream));
    CHECK_CUDA(cudaMemcpyAsync(d_w, h_w, EH * sizeof(int), cudaMemcpyHostToDevice, stream));
    CHECK_CUDA(cudaMemcpyAsync(h_dist, d_dist, V * sizeof(int), cudaMemcpyDeviceToHost, stream));
    CHECK_CUDA(cudaStreamSynchronize(stream));

    for (int r = 0; r < repeat; ++r) {
        CHECK_CUDA(cudaEventRecord(start, stream));
        CHECK_CUDA(cudaMemcpyAsync(d_row_ptr, h_row_ptr, (V + 1) * sizeof(int), cudaMemcpyHostToDevice, stream));
        CHECK_CUDA(cudaMemcpyAsync(d_col_idx, h_col_idx, EH * sizeof(int), cudaMemcpyHostToDevice, stream));
        CHECK_CUDA(cudaMemcpyAsync(d_w, h_w, EH * sizeof(int), cudaMemcpyHostToDevice, stream));
        CHECK_CUDA(cudaEventRecord(stop, stream));
        CHECK_CUDA(cudaEventSynchronize(stop));
        float ms = 0.0f;
        CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));
        h2d_sum += ms;

        CHECK_CUDA(cudaEventRecord(start, stream));
        CHECK_CUDA(cudaMemcpyAsync(h_dist, d_dist, V * sizeof(int), cudaMemcpyDeviceToHost, stream));
        CHECK_CUDA(cudaEventRecord(stop, stream));
        CHECK_CUDA(cudaEventSynchronize(stop));
        ms = 0.0f;
        CHECK_CUDA(cudaEventElapsedTime(&ms, start, stop));
        d2h_sum += ms;
    }

    float h2d_ms = h2d_sum / repeat;
    float d2h_ms = d2h_sum / repeat;
    float transfer_ms = h2d_ms + d2h_ms;

    write_csv_header_if_needed(out_csv);
    std::ofstream out(out_csv, std::ios::app);
    out << dataset << ',' << grid_n << ',' << V << ',' << EH << ',' << bytes_h2d << ',' << bytes_d2h << ',' << h2d_ms
        << ',' << d2h_ms << ',' << transfer_ms << '\n';

    std::cout << "[OK] " << dataset << " V=" << V << " EH=" << EH << " h2d_ms=" << h2d_ms << " d2h_ms=" << d2h_ms
              << " transfer_ms=" << transfer_ms << std::endl;

    CHECK_CUDA(cudaEventDestroy(start));
    CHECK_CUDA(cudaEventDestroy(stop));
    CHECK_CUDA(cudaStreamDestroy(stream));

    CHECK_CUDA(cudaFree(d_row_ptr));
    CHECK_CUDA(cudaFree(d_col_idx));
    CHECK_CUDA(cudaFree(d_w));
    CHECK_CUDA(cudaFree(d_dist));

    CHECK_CUDA(cudaFreeHost(h_row_ptr));
    CHECK_CUDA(cudaFreeHost(h_col_idx));
    CHECK_CUDA(cudaFreeHost(h_w));
    CHECK_CUDA(cudaFreeHost(h_dist));

    return 0;
}
