# Exp 4.4.1 — Line-graph topology rebuild speedup

This experiment measures the speedup of **line-graph topology CSR construction** (count → prefix-sum/scan → fill) on GPU versus a CPU baseline.

## Inputs

- `cwsp/data/*.edges` (only the `.edges` file is used here)

## How to run

From `cwsp/`:

- Build + run and generate CSV:

  ```bash
  REPEAT=10 ./scripts/run_exp4_4_1_topology.sh
  ```

- Plot CSV to PDF:

  ```bash
  ./scripts/plot_exp4_4_1_topology.py \
    --csv results/exp4_4_1_topology/csv/topology_speedup.csv \
    --out results/exp4_4_1_topology/topology_speedup.pdf
  ```

- Copy figure into thesis figures:

  ```bash
  cp results/exp4_4_1_topology/topology_speedup.pdf \
    latex_src/sysuthesis-2.0.0-beta4/figures/exp4_4_1_topology_speedup.pdf
  ```

## Outputs

- CSV: `results/exp4_4_1_topology/csv/topology_speedup.csv`
- Logs: `results/exp4_4_1_topology/logs/`
- Binary: `results/exp4_4_1_topology/bin/bench_topology`
- Figure (local): `results/exp4_4_1_topology/topology_speedup.pdf`
- Figure (thesis): `latex_src/sysuthesis-2.0.0-beta4/figures/exp4_4_1_topology_speedup.pdf`
