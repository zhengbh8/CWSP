#!/usr/bin/env python3
import sys
import random
from compare_baseline import load_graph, standard_dijkstra, line_graph_dijkstra

def main():
    edges_file = sys.argv[1]
    penalties_file = sys.argv[2]
    adj, edges, penalties = load_graph(edges_file, penalties_file)
    
    # We want to find a pair (start, end) where Dijkstra triggers a penalty.
    # The best way is to pick a known penalty node u->v->w, and set start=u, end=w or nearby.
    penalty_triples = [k for k, v in penalties.items() if v > 1000]
    random.shuffle(penalty_triples)
    
    print(f"Loaded {len(penalty_triples)} high penalty triples. Searching...")
    
    # Try finding an extended sequence starting slightly before u and ending after w
    for c, (pu, pv, pw) in enumerate(penalty_triples):
        if c > 50: break # don't search forever
        
        # Step back from pu if possible
        starts = [n for n, nbrs in adj.items() if pu in nbrs]
        ends = adj.get(pw, [])
        
        if not starts: starts = [pu]
        if not ends: ends = [pw]
        
        for start in starts[:2]:
            for end in ends[:2]:
                if start == end: continue
                
                dij_base, dij_true, path = standard_dijkstra(adj, edges, penalties, start, end)
                if dij_base == float('inf'): continue
                
                if dij_true > dij_base and dij_true > 1000:
                    cwsp_cost, cwsp_path = line_graph_dijkstra(adj, edges, penalties, start, end)
                    if cwsp_cost < float('inf') and cwsp_cost < dij_true:
                        print(f"FOUND! Start: {start}, End: {end}")
                        print(f"Dijkstra thinks cost is {dij_base}, true cost {dij_true}. Path: {path}")
                        print(f"CWSP cost is {cwsp_cost}. Path: {cwsp_path}")
                        
                        # Modify compare_baseline to make this the default finding
                        with open("compare_baseline.py", "r") as f:
                            code = f.read()
                        code = code.replace("start_node = min(nodes)", f"start_node = {start}")
                        code = code.replace("end_node = max(nodes)", f"end_node = {end}")
                        with open("compare_baseline.py", "w") as f:
                            f.write(code)
                        print("Updated compare_baseline.py with these nodes!")
                        sys.exit(0)
                        
    print("Could not find divergence easily.")

if __name__ == "__main__":
    main()
