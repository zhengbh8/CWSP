#include <iostream>
#include "../include/graph.cuh"

int main(int argc, char** argv) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <edges_file> <penalties_file>\n";
        return 1;
    }
    
    std::string edge_file = argv[1];
    std::string penalty_file = argv[2];
    
    std::cout << "[INFO] Loading original graph...\n";
    OriginalGraph g = load_original_graph(edge_file, penalty_file);
    std::cout << "       Original Graph Nodes: " << g.num_nodes << "\n";
    std::cout << "       Original Graph Edges: " << g.num_edges << "\n";
    std::cout << "       Penalties Loaded: " << g.penalties.size() << "\n";
    
    std::cout << "[INFO] Converting to Line Graph...\n";
    LineGraph lg = convert_to_line_graph(g);
    std::cout << "       Line Graph Nodes: " << lg.num_nodes << "\n";
    std::cout << "       Line Graph Edges: " << lg.num_edges << "\n";
    
    std::cout << "[INFO] Conversion successful! Ready for GPU processing.\n";
    
    return 0;
}
