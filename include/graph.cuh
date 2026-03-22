#pragma once

#include <vector>
#include <string>
#include <map>
#include <tuple>
#include <iostream>

// 原始图的边结构
struct OriginalEdge {
    int id;          // 映射到线图后的节点ID
    int u;           // 起点
    int v;           // 终点
    float weight;    // 基础通行代价
};

// 原始图结构 (G)
struct OriginalGraph {
    int num_nodes = 0;
    int num_edges = 0;
    std::vector<OriginalEdge> edges;
    
    // penalties[(u, v, w)] = 惩罚值
    std::map<std::tuple<int, int, int>, float> penalties;
};

// 线图的边结构 (CSR格式的前置形式)
// 线图的节点就是原图的边
struct LineGraphEdge {
    int src_node;    // 原图中的边 id_1 (u -> v)
    int dst_node;    // 原图中的边 id_2 (v -> w)
    float weight;    // 衍生权重: 目标边的基础代价 + 转弯惩罚
};

// 线图结构 (L(G))
struct LineGraph {
    int num_nodes;   // 线图节点数 = 原图边数
    int num_edges;   // 线图边数 = 原图中 (u->v) 和 (v->w) 的连接数
    std::vector<LineGraphEdge> edges;
    
    // CSR 格式数组 (用于下一步传输给 GPU)
    std::vector<int> row_ptr;
    std::vector<int> col_idx;
    std::vector<float> edge_weights;
};

// 函数声明
OriginalGraph load_original_graph(const std::string& edge_file, const std::string& penalty_file);
LineGraph convert_to_line_graph(const OriginalGraph& g);

