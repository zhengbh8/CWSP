#!/usr/bin/env python3
import os
import networkx as nx
import osmnx as ox
import math

def calculate_angle(u, v, w, graph):
    try:
        x1, y1 = graph.nodes[u]['x'], graph.nodes[u]['y']
        x2, y2 = graph.nodes[v]['x'], graph.nodes[v]['y']
        x3, y3 = graph.nodes[w]['x'], graph.nodes[w]['y']
        dx1, dy1 = x2 - x1, y2 - y1
        dx2, dy2 = x3 - x2, y3 - y2
        dot = dx1*dx2 + dy1*dy2
        det = dx1*dy2 - dy1*dx2
        angle = math.atan2(det, dot)
        deg = math.degrees(angle)
        return abs(deg)
    except KeyError:
        return 0

def main():
    print("Fetching Miami International Airport taxiways via BBox (bypassing Nominatim)...")
    north, south, east, west = 25.808, 25.782, -80.260, -80.310
    cf = '["aeroway"~"taxiway|runway"]'
    
    # Configure OSmnx to use overpass api directly and configure proxy if needed
    ox.settings.timeout = 180
    
    try:
        G = ox.graph_from_bbox(bbox=(north, south, east, west), custom_filter=cf, retain_all=True)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return

    G = nx.convert_node_labels_to_integers(G)
    print(f"Downloaded MIA graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
    
    out_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "../data"))
    os.makedirs(out_dir, exist_ok=True)
    edges_file = os.path.join(out_dir, "mia_airport.edges")
    penalties_file = os.path.join(out_dir, "mia_airport.penalties")
    
    edges_list = []
    with open(edges_file, 'w') as fe:
        fe.write("# Format: u v length(m)\n")
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
            
    num_penalties = 0
    with open(penalties_file, 'w') as fp:
        fp.write("# Format: u v w penalty\n")
        for u, v in edges_list:
            for nxt_v, w in simple_G.out_edges(v):
                if u == w:
                    fp.write(f"{u} {v} {w} 5000.0\n") 
                    num_penalties += 1
                else:
                    angle = calculate_angle(u, v, w, G)
                    if angle > 90.0:
                        fp.write(f"{u} {v} {w} 5000.0\n") 
                        num_penalties += 1
                    elif angle > 30.0:
                        fp.write(f"{u} {v} {w} 50.0\n")    
                        num_penalties += 1
                        
    print(f"✅ Success! Wrote {len(edges_list)} edges and {num_penalties} turn penalties.")

if __name__ == "__main__":
    main()
