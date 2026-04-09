import matplotlib.pyplot as plt
import numpy as np
import os

# Data from experiments
nodes = [10000, 20000, 50000, 100000]
edges = [499509, 1000488, 2498455, 5000152] 
cpu_times = [422.085, 845.412, 2111.19, 10562.8]
gpu_times = [10.5912, 21.2088, 52.9722, 106.003]
speedup = [39.8526, 39.8614, 39.8548, 99.6467]

# Deltas for U-Curve
deltas = [5, 10, 20, 30, 35, 45, 50, 70, 90]
delta_times = [17.0113, 9.99958, 7.80257, 9.72181, 11.4604, 16.3589, 19.3345, 35.0851, 56.3829]

os.makedirs('/root/autodl-tmp/cwsp/figures', exist_ok=True)

# 1. End to End Time
plt.figure(figsize=(8,6))
plt.plot(nodes, cpu_times, marker='o', label="CPU Total Time", linewidth=2)
plt.plot(nodes, gpu_times, marker='s', label="GPU Total Time", linewidth=2)
plt.xlabel("Graph Size (|V|)")
plt.ylabel("Time (ms)")
plt.title("End-to-End Time Comparison")
plt.legend()
plt.grid(True)
plt.yscale('log')
plt.savefig('/root/autodl-tmp/cwsp/figures/overall_time.png', dpi=300)

# 2. U-Curve for Delta
plt.figure(figsize=(8,6))
plt.plot(deltas, delta_times, marker='^', color='red', linewidth=2)
plt.xlabel("Delta Value ($\\Delta$)")
plt.ylabel("Time (ms)")
plt.title("$\\Delta$-Stepping Parameter Tuning")
plt.grid(True)
plt.savefig('/root/autodl-tmp/cwsp/figures/delta_ucurve.png', dpi=300)
