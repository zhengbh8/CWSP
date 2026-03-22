#!/usr/bin/env python3
import os
import networkx as nx
import osmnx as ox
import math

def calculate_angle(u, v, w, graph):
    """
    计算 u -> v -> w 路线的夹角。
    返回值: 夹角的绝对值(度数)，范围 [0, 180]。0表示直行，180表示掉头。
    """
    try:
        x1, y1 = graph.nodes[u]['x'], graph.nodes[u]['y']
        x2, y2 = graph.nodes[v]['x'], graph.nodes[v]['y']
        x3, y3 = graph.nodes[w]['x'], graph.nodes[w]['y']
        
        # 向量 v1: u -> v
        dx1, dy1 = x2 - x1, y2 - y1
        # 向量 v2: v -> w
        dx2, dy2 = x3 - x2, y3 - y2
        
        dot = dx1*dx2 + dy1*dy2
        det = dx1*dy2 - dy1*dx2
        angle = math.atan2(det, dot)
        deg = math.degrees(angle)
        
        return abs(deg)
    except KeyError:
        return 0

def main():
    place_name = "Miami International Airport, United States"
    print(f"Fetching data for {place_name} via OSMNX...")
    
    # 机场滑行道 custom_filter
    cf = '["aeroway"~"taxiway|runway"]'
    try:
        G = ox.graph_from_place(place_name, custom_filter=cf, retain_all=True)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return

    # 这里获取的是一个 MultiDiGraph
    # 我们先将其重新编号为0开始的连续ID
    G = nx.convert_node_labels_to_integers(G)
    
    print(f"Downloaded graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
    
    out_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "../data"))
    os.makedirs(out_dir, exist_ok=True)
    edges_file = os.path.join(out_dir, "mia_airport.edges")
    penalties_file = os.path.join(out_dir, "mia_airport.penalties")
    
    edges_list = []
    # 写入边数据
    with open(edges_file, 'w') as fe:
        fe.write("# Format: u v length(m)\n")
        # MultiDiGraph 可能有很多同向边，为了简化基线，只取最短的那条
        simple_G = nx.DiGraph()
        for u, v, data in G.edges(data=True):
            length = float(data.get('length', 10.0))
            if simple_G.has_edge(u, v):
                simple_G[u][v]['length'] = min(simple_G[u][v]['length'], length)
            else:
                simple_G.add_edge(u, v, length=length)
                
        for u, v, data in simple_G.edges(data=True):
            edges_list.append((u, v))
            fe.write(f"{u} {v} {data['length']:.2f}\n")
            
    # 计算转弯角度并设定惩罚
    # 论文设定：如果转弯角度 > 90度 (即锐角转弯 or 掉头)，设定极高惩罚(比如 99999) 模拟 "prohibited"
    # 平缓的弯道则无惩罚或微小惩罚。
    print("Computing turn penalties based on geometric angles...")
    num_penalties = 0
    with open(penalties_file, 'w') as fp:
        fp.write("# Format: u v w penalty\n")
        # 遍历所有长度为2的路径 u -> v -> w
        for u, v in edges_list:
            for nxt_v, w in simple_G.out_edges(v):
                if u == w: # u -> v -> u 掉头
                    fp.write(f"{u} {v} {w} 99999.0\n")
                    num_penalties += 1
                else:
                    angle = calculate_angle(u, v, w, G)
                    # angle 等于0 是直行，大于90度属于尖锐拐点
                    if angle > 90.0:
                        fp.write(f"{u} {v} {w} 99999.0\n") # 禁止锐角转弯
                        num_penalties += 1
                    elif angle > 30.0:
                        fp.write(f"{u} {v} {w} 50.0\n")    # 一般转弯有减速代价
                        num_penalties += 1
                        
    print(f"✅ Success! Wrote {len(edges_list)} edges and {num_penalties} turn penalties.")
    print(f"File 1: {edges_file}")
    print(f"File 2: {penalties_file}")

if __name__ == "__main__":
    main()
