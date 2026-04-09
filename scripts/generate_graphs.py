import networkx as nx
import random
import os
import time

def generate_graph(n, m, density_type, scale_name):
    print(f"Generating {density_type} graph: {n} nodes, {m} edges...")
    start_time = time.time()
    
    # Generate random directed graph with exact number of nodes and edges
    G = nx.gnm_random_graph(n, m, directed=True)
    
    # Ensure graph is strongly connected for SPP (optional, but good for testing)
    # To keep it simple and strict to m edges, we just take the large component or leave it.
    
    # Add random weights to edges [1, 100]
    out_dir = "/root/autodl-tmp/cwsp/data/syn/"
    edge_file = os.path.join(out_dir, f"{density_type}_{scale_name}.edges")
    
    edges_info = []
    edges = list(G.edges())
    # Create internal edge IDs for Line Graph mapping
    edge_to_id = {}
    for i, (u, v) in enumerate(edges):
        w = random.randint(1, 100)
        edges_info.append(f"{i} {u} {v} {w}\n")
        edge_to_id[(u, v)] = i
        
    with open(edge_file, 'w') as f:
        f.writelines(edges_info)
        
    # Generate Line Graph size (num of transitions)
    # L(G) edges = sum(out_degree(u) * in_degree(u)) for u in V
    in_deg = {n: 0 for n in G.nodes()}
    out_deg = {n: 0 for n in G.nodes()}
    for u, v in edges:
        in_deg[v] += 1
        out_deg[u] += 1
        
    L_V = m
    L_E = sum(in_deg[node] * out_deg[node] for node in G.nodes())
    
    print(f"  -> Original Graph: |V|={n}, |E|={m}")
    print(f"  -> Line Graph L(G): |V|={L_V}, |E|={L_E}")
    print(f"  -> Saved to {edge_file} in {time.time()-start_time:.2f}s\n")
    return L_E

if __name__ == "__main__":
    random.seed(42)
    # Define configurations
    # Density rule: 
    # Sparse: avg degree ~ 5 -> n = m / 5
    # Dense: avg degree ~ 50 -> n = m / 50
    configs = [
        {"scale": "10K",  "m": 10000,  "sparse_n": 2000,  "dense_n": 200},
        {"scale": "20K",  "m": 20000,  "sparse_n": 4000,  "dense_n": 400},
        {"scale": "50K",  "m": 50000,  "sparse_n": 10000, "dense_n": 1000},
        {"scale": "100K", "m": 100000, "sparse_n": 20000, "dense_n": 2000}
    ]
    
    results = []
    for cfg in configs:
        le_s = generate_graph(cfg["sparse_n"], cfg["m"], "sparse", cfg["scale"])
        le_d = generate_graph(cfg["dense_n"], cfg["m"], "dense", cfg["scale"])
        results.append((cfg["scale"], cfg["m"], cfg["sparse_n"], le_s, cfg["dense_n"], le_d))
        
    print("=== SUMMARY TABLE ===")
    print(f"{'Scale':<6} | {'Original |E|':<12} | {'Sparse |V|':<10} | {'Sparse L(G) |E|':<16} | {'Dense |V|':<10} | {'Dense L(G) |E|'}")
    print("-" * 80)
    for res in results:
        print(f"{res[0]:<6} | {res[1]:<12} | {res[2]:<10} | {res[3]:<16} | {res[4]:<10} | {res[5]}")

