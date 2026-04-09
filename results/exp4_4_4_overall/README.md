# EXP 4.4.4 Overall end-to-end scaling

This experiment reports an end-to-end timing breakdown and overall speedup of the CWSP GPU pipeline.

We aggregate three phases (each phase timed independently):

1) Line-graph topology construction (CPU vs GPU)
2) Conditional weight computation (CPU vs GPU SIMT)
3) SSSP optimization (CPU Dijkstra vs GPU Δ-stepping)

Additionally, we measure a representative transfer overhead (H2D for CSR+weights + D2H for dist array) and include it in the GPU total.

## Run

```bash
cd cwsp
bash scripts/run_exp4_4_4_overall.sh
```

## Outputs

- Intermediate CSVs:
  - `results/exp4_4_4_overall/csv/topology.csv`
  - `results/exp4_4_4_overall/csv/weight.csv`
  - `results/exp4_4_4_overall/csv/sssp.csv`
  - `results/exp4_4_4_overall/csv/transfer.csv`

- Merged CSV:
  - `results/exp4_4_4_overall/csv/overall.csv`

- Figure:
  - `results/exp4_4_4_overall/figures/overall_time.png`
  - copied to thesis: `latex_src/sysuthesis-2.0.0-beta4/figures/overall_time.png`
