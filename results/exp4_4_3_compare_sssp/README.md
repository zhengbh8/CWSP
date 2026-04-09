# EXP 4.4.3 SSSP Compare (CPU Dijkstra vs GPU Δ-Stepping)

This experiment produces a reproducible efficiency comparison between:
- CPU baseline: serial Dijkstra (priority queue)
- GPU method: bucketed Δ-stepping (all edge weights <= Δ)

The experiment runs on grid_NxN datasets and operates on the **line graph** constructed from the original directed grid.
Edge weights on the line graph are computed as:

`w_L(e1 -> e2) = base_weight(e2) + turn_penalty(e1,e2)`

where `turn_penalty` is applied when the movement direction changes.

## Run

```bash
cd cwsp
REPEAT=3 DELTA=16 TURN_PENALTY=10 bash scripts/run_exp4_4_3_compare_sssp.sh
```

## Outputs

- CSV: `results/exp4_4_3_compare_sssp/csv/dijkstra_vs_delta.csv`
- LaTeX table (copied for thesis):
  - `latex_src/sysuthesis-2.0.0-beta4/figures/tab_exp_phase3_dijkstra_vs_delta.tex`
