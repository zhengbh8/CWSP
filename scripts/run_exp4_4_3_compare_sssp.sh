#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_DIR="$ROOT_DIR/results/exp4_4_3_compare_sssp"
BIN_DIR="$RESULT_DIR/bin"
LOG_DIR="$RESULT_DIR/logs"
CSV_DIR="$RESULT_DIR/csv"
FIG_DIR="$RESULT_DIR/figures"

mkdir -p "$BIN_DIR" "$LOG_DIR" "$CSV_DIR" "$FIG_DIR"

BIN="$BIN_DIR/bench_sssp_compare"
OUT_CSV="$CSV_DIR/dijkstra_vs_delta.csv"

SM="${SM:-86}"  # RTX 3090 = sm_86
DELTA="${DELTA:-35}"
TURN_PENALTY="${TURN_PENALTY:-10}"
REPEAT="${REPEAT:-3}"

# Grid sizes to benchmark (N x N)
SIZES=(100 150 200 250 300)

: > "$OUT_CSV"

echo "[1/4] Build bench_sssp_compare (SM=$SM)"
nvcc -O3 -std=c++17 -lineinfo \
  -arch="sm_${SM}" \
  "$ROOT_DIR/src/bench_sssp_compare.cu" -o "$BIN" \
  |& tee "$LOG_DIR/build.log"

echo "[2/4] Generate datasets"
for N in "${SIZES[@]}"; do
  python3 "$ROOT_DIR/scripts/generate_grid_edges_only.py" -N "$N" --out-dir "../data" --seed 42 --wmin 1 --wmax 5 \
    |& tee "$LOG_DIR/gen_grid_${N}.log"
done

echo "[3/4] Run CPU Dijkstra vs GPU Δ-stepping"
for N in "${SIZES[@]}"; do
  DATASET="grid_${N}x${N}"
  EDGES="$ROOT_DIR/data/${DATASET}.edges"
  echo "[RUN] $DATASET"
  "$BIN" --dataset "$DATASET" --edges "$EDGES" --out "$OUT_CSV" \
    --delta "$DELTA" --turn-penalty "$TURN_PENALTY" --repeat "$REPEAT" \
    |& tee "$LOG_DIR/run_${DATASET}.log"
done

echo "[4/4] Make LaTeX table"
python3 "$ROOT_DIR/scripts/make_tab_exp4_4_3_compare_sssp.py" \
  --csv "$OUT_CSV" \
  --out-tex "$ROOT_DIR/latex_src/sysuthesis-2.0.0-beta4/figures/tab_exp_phase3_dijkstra_vs_delta.tex"

echo "[DONE] CSV: $OUT_CSV"
