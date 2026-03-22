#!/usr/bin/env python3
import warnings
import heapq
import sys

def load_graph(edges_file, penalties_file):
    adj = {}
    edges = {}
    with open(edges_file, 'r') as f:
        for line in f:
            if line.startswith('#'): continue
            parts = line.strip().split()
            if len(parts) >= 3:
                u, v, w = int(parts[0]), int(parts[1]), float(parts[2])
                if u not in adj: adj[u] = []
                adj[u].append(v)
                edges[(u, v)] = w
                
    penalties = {}
    if penalties_file:
        with open(penalties_file, 'r') as f:
            for line in f:
                if line.startswith('#'): continue
                parts = line.strip().split()
                if len(parts) >= 4:
                    u, v, w, p = int(parts[0]), int(parts[1]), int(parts[2]), float(parts[3])
                    penalties[(u, v, w)] = p
    return adj, edges, penalties

def evaluate_true_cost(path, edges, penalties):
    if len(path) < 2: return 0
    cost = 0
    for i in range(len(path)-1):
        cost += edges[(path[i], path[i+1])]
    for i in range(len(path)-2):
        u, v, w = path[i], path[i+1], path[i+2]
        cost += penalties.get((u, v, w), 0)
    return cost

def standard_dijkstra(adj, edges, penalties, start, end):
    # Ignoring penalties completely
    queue = [(0, start, [start])]
    visited = set()
    while queue:
        cost, curr, path = heapq.heappop(queue)
        if curr == end:
            true_c = evaluate_true_cost(path, edges, penalties)
            return cost, true_c, path
        
        if curr in visited: continue
        visited.add(curr)
        
        for nxt in adj.get(curr, []):
            if nxt not in visited:
                heapq.heappush(queue, (cost + edges[(curr, nxt)], nxt, path + [nxt]))
    return float('inf'), float('inf'), []

def line_graph_dijkstra(adj, edges, penalties, start, end):
    # Standard Dijkstra on Line Graph
    # Nodes in Line Graph are edges in OG: (u, v)
    # Start: we can start at any (start, v) with cost edges[(start, v)]
    queue = []
    visited = set()
    
    for v in adj.get(start, []):
        queue.append((edges[(start, v)], (start, v), [start, v]))
    heapq.heapify(queue)
    
    while queue:
        cost, (u, v), path = heapq.heappop(queue)
        
        if v == end:
            return cost, path
            
        if (u, v) in visited: continue
        visited.add((u, v))
        
        for w in adj.get(v, []):
            if (v, w) not in visited:
                # Cost to move from (u,v) to (v,w) is base cost of (v,w) + penalty(u,v,w)
                p = penalties.get((u, v, w), 0)
                nxt_cost = cost + edges[(v, w)] + p
                heapq.heappush(queue, (nxt_cost, (v, w), path + [w]))
                
    return float('inf'), []

def main():
    if len(sys.argv) < 3:
        print("Usage: python compare_baseline.py <edges_file> <penalties_file>")
        sys.exit(1)
        
    edges_file = sys.argv[1]
    penalties_file = sys.argv[2]
    
    adj, edges, penalties = load_graph(edges_file, penalties_file)
    
    # 假设我们找 0 到 N*N-1 的路径。我们可以从数据中找出最小和最大节点
    nodes = set(adj.keys())
    for v_list in adj.values():
         nodes.update(v_list)
    start_node = 2617
    end_node = 2988
    
    print("========================================")
    print(" 核心实验一：传统 Dijkstra vs 线图 CWSP ")
    print("========================================")
    
    naive_base_cost, naive_true_cost, naive_path = standard_dijkstra(adj, edges, penalties, start_node, end_node)
    print("\n[方案 A] 传统 Dijkstra (无视前驱约束，纯贪心)")
    print(f" -> 认为的最短路径长度 : {naive_base_cost}")
    print(f" -> 产生的路径序列     : {naive_path}")
    print(f" -> 该路径的【真实代价】: {naive_true_cost}")
    if naive_true_cost > 100:
        print("    >> ⚠️ 结论：该路径包含了非法的锐角转弯/高昂惩罚，在现实中【不可行】！")
        
    cwsp_true_cost, cwsp_path = line_graph_dijkstra(adj, edges, penalties, start_node, end_node)
    print("\n[方案 B] 基于线图的 CWSP 算法 (完美适配 1-加性转弯惩罚)")
    print(f" -> 产生的路径序列     : {cwsp_path}")
    print(f" -> 该路径的【真实代价】: {cwsp_true_cost}")
    print(f" -> 理论最短路径长度   : {cwsp_true_cost}")
    if cwsp_true_cost < naive_true_cost:
        print("    >> ✅ 结论：避开了非法约束，成功找到了具有全局合法最优解的路线！")

if __name__ == "__main__":
    main()
