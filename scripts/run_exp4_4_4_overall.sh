#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_DIR="$ROOT_DIR/results/exp4_4_4_overall"
BIN_DIR="$RESULT_DIR/bin"
LOG_DIR="$RESULT_DIR/logs"
CSV_DIR="$RESULT_DIR/csv"
FIG_DIR="$RESULT_DIR/figures"

mkdir -p "$BIN_DIR" "$LOG_DIR" "$CSV_DIR" "$FIG_DIR"

SM="${SM:-86}"  # RTX 3090 = sm_86
REPEAT_TOPO="${REPEAT_TOPO:-5}"
REPEAT_WEIGHT="${REPEAT_WEIGHT:-5}"
REPEAT_SSSP="${REPEAT_SSSP:-3}"
REPEAT_XFER="${REPEAT_XFER:-5}"

DELTA="${DELTA:-35}"
TURN_PENALTY="${TURN_PENALTY:-10}"

# Grid sizes to benchmark (N x N)
SIZES=(100 150 200 250 300)

BIN_TOPO="$BIN_DIR/bench_topology"
BIN_WEIGHT="$BIN_DIR/bench_weight"
BIN_SSSP="$BIN_DIR/bench_sssp_compare"
BIN_XFER="$BIN_DIR/bench_h2d_overall"

CSV_TOPO="$CSV_DIR/topology.csv"
CSV_WEIGHT="$CSV_DIR/weight.csv"
CSV_SSSP="$CSV_DIR/sssp.csv"
CSV_XFER="$CSV_DIR/transfer.csv"
CSV_MERGED="$CSV_DIR/overall.csv"

FIG_OUT="$FIG_DIR/overall_time.png"

: > "$CSV_TOPO"
: > "$CSV_WEIGHT"
: > "$CSV_SSSP"
: > "$CSV_XFER"


echo "[1/6] Build benchmarks (SM=$SM)"
nvcc -O3 -std=c++17 -lineinfo -arch="sm_${SM}" -I"$ROOT_DIR/include" \
  "$ROOT_DIR/src/bench_topology.cu" -o "$BIN_TOPO" |& tee "$LOG_DIR/build_topology.log"

nvcc -O3 -std=c++17 -lineinfo -arch="sm_${SM}" -I"$ROOT_DIR/include" \
  "$ROOT_DIR/src/bench_weight.cu" -o "$BIN_WEIGHT" |& tee "$LOG_DIR/build_weight.log"

nvcc -O3 -std=c++17 -lineinfo -arch="sm_${SM}" \
  "$ROOT_DIR/src/bench_sssp_compare.cu" -o "$BIN_SSSP" |& tee "$LOG_DIR/build_sssp.log"

nvcc -O3 -std=c++17 -lineinfo -arch="sm_${SM}" \
  "$ROOT_DIR/src/bench_h2d_overall.cu" -o "$BIN_XFER" |& tee "$LOG_DIR/build_xfer.log"


echo "[2/6] Generate datasets"
for N in "${SIZES[@]}"; do
  python3 "$ROOT_DIR/scripts/generate_grid_edges_only.py" -N "$N" --out-dir "../data" --seed 42 --wmin 1 --wmax 5 \
    |& tee "$LOG_DIR/gen_grid_${N}.log"
done


echo "[3/6] Phase-1 topology (CPU vs GPU)"
for N in "${SIZES[@]}"; do
  DATASET="grid_${N}x${N}"
  EDGES="$ROOT_DIR/data/${DATASET}.edges"
  echo "- $DATASET"
  "$BIN_TOPO" --dataset "$DATASET" --edges "$EDGES" --repeat "$REPEAT_TOPO" --out "$CSV_TOPO" \
    |& tee "$LOG_DIR/run_topo_${DATASET}.log"
done


echo "[4/6] Phase-2 weights (CPU vs GPU SIMT)"
for N in "${SIZES[@]}"; do
  DATASET="grid_${N}x${N}"
  EDGES="$ROOT_DIR/data/${DATASET}.edges"
  echo "- $DATASET"
  "$BIN_WEIGHT" --dataset "$DATASET" --edges "$EDGES" --repeat "$REPEAT_WEIGHT" --out "$CSV_WEIGHT" \
    |& tee "$LOG_DIR/run_weight_${DATASET}.log"
done


echo "[5/6] Phase-3 SSSP (CPU Dijkstra vs GPU Δ-stepping) + transfer"
for N in "${SIZES[@]}"; do
  DATASET="grid_${N}x${N}"
  EDGES="$ROOT_DIR/data/${DATASET}.edges"
  echo "- $DATASET"
  "$BIN_SSSP" --dataset "$DATASET" --edges "$EDGES" --out "$CSV_SSSP" \
    --delta "$DELTA" --turn-penalty "$TURN_PENALTY" --repeat "$REPEAT_SSSP" \
    |& tee "$LOG_DIR/run_sssp_${DATASET}.log"

  "$BIN_XFER" --dataset "$DATASET" --edges "$EDGES" --out "$CSV_XFER" \
    --turn-penalty "$TURN_PENALTY" --repeat "$REPEAT_XFER" \
    |& tee "$LOG_DIR/run_xfer_${DATASET}.log"
done


echo "[6/6] Merge + plot + copy into LaTeX figures"
python3 "$ROOT_DIR/scripts/merge_exp4_4_4_overall.py" \
  --topo "$CSV_TOPO" --weight "$CSV_WEIGHT" --sssp "$CSV_SSSP" --xfer "$CSV_XFER" --out "$CSV_MERGED"

python3 "$ROOT_DIR/scripts/plot_exp4_4_4_overall.py" --csv "$CSV_MERGED" --out "$FIG_OUT"

TAB_OUT="$FIG_DIR/tab_exp_phase4_overall_breakdown.tex"
python3 "$ROOT_DIR/scripts/make_tab_exp4_4_4_overall_breakdown.py" --csv "$CSV_MERGED" --out "$TAB_OUT"

cp "$FIG_OUT" "$ROOT_DIR/latex_src/sysuthesis-2.0.0-beta4/figures/overall_time.png"
cp "$TAB_OUT" "$ROOT_DIR/latex_src/sysuthesis-2.0.0-beta4/figures/tab_exp_phase4_overall_breakdown.tex"


echo "[DONE] merged CSV: $CSV_MERGED"
