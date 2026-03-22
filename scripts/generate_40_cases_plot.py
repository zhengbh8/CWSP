#!/usr/bin/env python3
import sys
import random
from collections import deque
import matplotlib.pyplot as plt
import seaborn as sns
from compare_baseline import load_graph, standard_dijkstra, line_graph_dijkstra

def bfs_distances(adj, start):
    distances = {start: 0}
    q = deque([start])
    while q:
        curr = q.popleft()
        d = distances[curr]
        for nxt in adj.get(curr, []):
            if nxt not in distances:
                distances[nxt] = d + 1
                q.append(nxt)
    return distances

def main():
    edges_file = sys.argv[1]
    penalties_file = sys.argv[2]
    out_img = sys.argv[3]
    
    print("Loading graph data for 40-case experiment...")
    adj, edges, penalties = load_graph(edges_file, penalties_file)
    nodes = list(adj.keys())
    
    random.seed(42)  # For reproducibility
    
    results = []
    seen_pairs = set()
    
    print("Finding 40 valid node pairs (min hop distance >= 20)...")
    attempts = 0
    while len(results) < 40 and attempts < 2000:
        attempts += 1
        u = random.choice(nodes)
        dists = bfs_distances(adj, u)
        
        valid_v = [v for v, d in dists.items() if d >= 20]
        if not valid_v: continue
        
        v = random.choice(valid_v)
        if (u, v) in seen_pairs: continue
        
        # Test paths
        dij_num, dij_real, _ = standard_dijkstra(adj, edges, penalties, u, v)
        if dij_num == float('inf'): continue 
        
        cwsp_cost, _ = line_graph_dijkstra(adj, edges, penalties, u, v)
        if cwsp_cost == float('inf'): continue 

        results.append({
            'id': len(results) + 1,
            'u': u, 'v': v,
            'dij_num': dij_num,
            'dij_real': dij_real,
            'cwsp_cost': cwsp_cost
        })
        seen_pairs.add((u, v))
        sys.stdout.write(f"\rGenerated {len(results)}/40 cases...")
        sys.stdout.flush()

    print("\nSimulation complete. Plotting data...")
    
    # Calculate stats
    dijkstra_success = sum(1 for r in results if r['dij_real'] == r['dij_num'])
    cwsp_success = sum(1 for r in results if r['cwsp_cost'] < float('inf'))
    print(f"Dijkstra success rate: {dijkstra_success}/40 ({(dijkstra_success/40)*100:.1f}%)")
    print(f"CWSP success rate: {cwsp_success}/40 ({(cwsp_success/40)*100:.1f}%)")
    
    # Set up matplotlib style (English labels to avoid TeX font issues, TeX will handle caption)
    sns.set_theme(style="whitegrid")
    fig, axes = plt.subplots(2, 1, figsize=(10, 8), gridspec_kw={'height_ratios': [3, 1]})
    
    ax = axes[0]
    cases = [r['id'] for r in results]
    cwsp_costs = [r['cwsp_cost'] for r in results]
    
    # Plot CWSP costs
    ax.plot(cases, cwsp_costs, marker='o', linestyle='-', color='blue', label='CWSP Cost (Always Valid)', zorder=2)
    
    # Plot Dijkstra
    dij_valid_cases = []
    dij_valid_costs = []
    dij_invalid_cases = []
    
    for r in results:
        if r['dij_real'] > r['dij_num'] and r['dij_real'] > 1000:
            dij_invalid_cases.append(r['id'])
        else:
            dij_valid_cases.append(r['id'])
            dij_valid_costs.append(r['dij_num'])
            
    # Mark invalid Dijkstra
    if dij_invalid_cases:
        max_cost = max(cwsp_costs + (dij_valid_costs if dij_valid_costs else [0]))
        ax.scatter(dij_invalid_cases, [max_cost * 1.1] * len(dij_invalid_cases), 
                   marker='X', color='red', s=100, label='Dijkstra Failed (Infeasible Turn)', zorder=3)
                   
    # Plot valid Dijkstra
    if dij_valid_cases:
        ax.scatter(dij_valid_cases, dij_valid_costs, marker='s', color='green', s=60, label='Dijkstra Cost (Valid)', zorder=3)
        
    ax.set_ylabel("Geometrical Distance Cost (meters)", fontsize=12)
    ax.set_title("Path Cost Comparison: CWSP vs Traditional Dijkstra", fontsize=14, pad=15)
    ax.set_xticks(range(1, 41, 2))
    ax.set_ylim(0, max_cost * 1.25)
    ax.legend(loc='upper right', fontsize=11)
    
    # Axis 2: Success rate bar chart
    ax2 = axes[1]
    algos = ['Traditional Dijkstra', 'Line Graph CWSP']
    rates = [(dijkstra_success/40)*100, (cwsp_success/40)*100]
    colors = ['#ff6b6b', '#2ca02c']
    
    bars = ax2.barh(algos, rates, color=colors, height=0.4)
    ax2.set_xlim(0, 110)
    ax2.set_xlabel("Optimal Feasible Path Success Rate (%)", fontsize=12)
    
    for bar in bars:
        ax2.text(bar.get_width() + 2, bar.get_y() + bar.get_height()/2 - 0.05, 
                 f"{bar.get_width():.1f}%", fontsize=12, fontweight='bold')

    plt.tight_layout()
    plt.savefig(out_img, format='pdf', bbox_inches='tight')
    print(f"Chart saved successfully at {out_img}!")

if __name__ == "__main__":
    main()
