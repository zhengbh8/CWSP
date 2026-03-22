#include "../include/graph.cuh"
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <algorithm>

OriginalGraph load_original_graph(const std::string& edge_file, const std::string& penalty_file) {
    OriginalGraph g;
    int max_node_id = -1;
    
    // 1. 读取基础边文件
    std::ifstream e_in(edge_file);
    if (!e_in) {
        throw std::runtime_error("Cannot open edge file: " + edge_file);
    }
    std::string line;
    int edge_id = 0;
    while (std::getline(e_in, line)) {
        if (line.empty() || line[0] == '#') continue;
        std::stringstream ss(line);
        int u, v; float w;
        if (ss >> u >> v >> w) {
            g.edges.push_back({edge_id++, u, v, w});
            max_node_id = std::max({max_node_id, u, v});
        }
    }
    g.num_edges = edge_id;
    g.num_nodes = max_node_id + 1;
    
    // 2. 读取转弯惩罚
    std::ifstream p_in(penalty_file);
    if (!p_in) {
        throw std::runtime_error("Cannot open penalty file: " + penalty_file);
    }
    while (std::getline(p_in, line)) {
        if (line.empty() || line[0] == '#') continue;
        std::stringstream ss(line);
        int u, v, w; float penalty;
        if (ss >> u >> v >> w >> penalty) {
            g.penalties[{u, v, w}] = penalty;
        }
    }
    
    return g;
}

LineGraph convert_to_line_graph(const OriginalGraph& g) {
    LineGraph lg;
    lg.num_nodes = g.num_edges;
    
    // 建立从节点 v 发出的所有边的索引 (v -> list of edges)
    std::vector<std::vector<const OriginalEdge*>> out_edges(g.num_nodes);
    for (const auto& e : g.edges) {
        out_edges[e.u].push_back(&e);
    }
    
    // 遍历所有原图边 e1 (u->v)
    for (const auto& e1 : g.edges) {
        // e1 的终点 v 必须与 e2 的起点相同 (v->w)
        for (const OriginalEdge* e2_ptr : out_edges[e1.v]) {
            const OriginalEdge& e2 = *e2_ptr;
            
            // 查找从 e1 到 e2 的转弯惩罚 (u -> v -> w)
            float penalty = 0.0f;
            auto it = g.penalties.find({e1.u, e1.v, e2.v});
            if (it != g.penalties.end()) {
                penalty = it->second;
            }
            
            // 线图中边的权重定义为：走入下一条原图边的基础代价 + 转弯所付出的附加代价
            float weight = e2.weight + penalty;
            
            lg.edges.push_back({e1.id, e2.id, weight});
        }
    }
    lg.num_edges = lg.edges.size();
    
    // 转换为 CSR 格式方便传入 GPU
    // CSR: row_ptr(num_nodes+1), col_idx(num_edges), edge_weights(num_edges)
    lg.row_ptr.assign(lg.num_nodes + 1, 0);
    for (const auto& e : lg.edges) {
        lg.row_ptr[e.src_node + 1]++;
    }
    // 前缀和
    for (int i = 0; i < lg.num_nodes; ++i) {
        lg.row_ptr[i+1] += lg.row_ptr[i];
    }
    
    lg.col_idx.resize(lg.num_edges);
    lg.edge_weights.resize(lg.num_edges);
    
    // 临时拷贝当前写入位置
    std::vector<int> current_row_ptr = lg.row_ptr;
    for (const auto& e : lg.edges) {
        int idx = current_row_ptr[e.src_node]++;
        lg.col_idx[idx] = e.dst_node;
        lg.edge_weights[idx] = e.weight;
    }
    
    return lg;
}
