#!/usr/bin/env python3
import os
import requests
import json
import math

def calculate_angle(n1, n2, n3):
    x1, y1 = n1['lon'], n1['lat']
    x2, y2 = n2['lon'], n2['lat']
    x3, y3 = n3['lon'], n3['lat']
    
    # 简单的平面投影差
    dx1, dy1 = x2 - x1, y2 - y1
    dx2, dy2 = x3 - x2, y3 - y2
    
    dot = dx1*dx2 + dy1*dy2
    det = dx1*dy2 - dy1*dx2
    angle = math.atan2(det, dot)
    return abs(math.degrees(angle))

def haversine(lon1, lat1, lon2, lat2):
    R = 6371000 # Earth radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1-a))

def main():
    print("Fetching Miami International Airport from Overpass API (pure requests)...")
    
    # query MIA airport taxiways (approx 5km radius around center)
    query = """
    [out:json];
    way(around:5000, 25.795, -80.285)["aeroway"~"taxiway|runway"];
    (._;>;);
    out;
    """
    
    try:
        response = requests.post("https://overpass-api.de/api/interpreter", data={"data": query}, timeout=60)
        data = response.json()
    except Exception as e:
        print(f"Failed to fetch data: {e}")
        return
        
    nodes = {}
    ways = []
    
    for element in data['elements']:
        if element['type'] == 'node':
            nodes[element['id']] = {'lat': element['lat'], 'lon': element['lon']}
        elif element['type'] == 'way':
            ways.append(element['nodes'])

    if not nodes:
        print("No nodes found!")
        return

    # Map node IDs to 0-based index
    valid_node_ids = set()
    for w in ways:
        valid_node_ids.update(w)
        
    node_to_idx = {nid: i for i, nid in enumerate(valid_node_ids)}
    
    out_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "../data"))
    os.makedirs(out_dir, exist_ok=True)
    edges_file = os.path.join(out_dir, "real_mia.edges")
    penalties_file = os.path.join(out_dir, "real_mia.penalties")
    
    edges_list = []
    adjacency = {}
    
    # 建立边
    with open(edges_file, 'w') as fe:
        fe.write("# Format: u v length(m)\n")
        
        for w_nodes in ways:
            # 双向建立连线
            for i in range(len(w_nodes)-1):
                n1_id = w_nodes[i]
                n2_id = w_nodes[i+1]
                
                u, v = node_to_idx[n1_id], node_to_idx[n2_id]
                
                dist = haversine(nodes[n1_id]['lon'], nodes[n1_id]['lat'],
                                 nodes[n2_id]['lon'], nodes[n2_id]['lat'])
                dist = max(dist, 1.0) # Avoid 0-dist
                
                # u -> v
                fe.write(f"{u} {v} {dist:.2f}\n")
                edges_list.append((u, v))
                if u not in adjacency: adjacency[u] = []
                adjacency[u].append(v)
                
                # v -> u (双向滑行)
                fe.write(f"{v} {u} {dist:.2f}\n")
                edges_list.append((v, u))
                if v not in adjacency: adjacency[v] = []
                adjacency[v].append(u)

    print(f"Parsed {len(valid_node_ids)} nodes and {len(edges_list)} edges.")
    
    idx_to_node = {i: nid for nid, i in node_to_idx.items()}
    num_penalties = 0

    with open(penalties_file, 'w') as fp:
        fp.write("# Format: u v w penalty\n")
        # u -> v -> w
        for u in adjacency:
            for v in adjacency[u]:
                for w in adjacency.get(v, []):
                    if u == w:
                        fp.write(f"{u} {v} {w} 5000.0\n") # u-turn
                        num_penalties += 1
                        continue
                        
                    n1 = nodes[idx_to_node[u]]
                    n2 = nodes[idx_to_node[v]]
                    n3 = nodes[idx_to_node[w]]
                    angle = calculate_angle(n1, n2, n3)
                    
                    if angle > 90.0:
                        fp.write(f"{u} {v} {w} 5000.0\n") # 锐角转弯
                        num_penalties += 1
                    elif angle > 30.0:
                        fp.write(f"{u} {v} {w} 50.0\n")   # 缓和弯道
                        num_penalties += 1

    print(f"✅ Success! Wrote penalties: {num_penalties}")
    
if __name__ == "__main__":
    main()
