#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_DIR="$ROOT_DIR/results/exp4_4_2_weight"
BIN_DIR="$RESULT_DIR/bin"
LOG_DIR="$RESULT_DIR/logs"
CSV_DIR="$RESULT_DIR/csv"

mkdir -p "$BIN_DIR" "$LOG_DIR" "$CSV_DIR"

BIN="$BIN_DIR/bench_weight"
OUT_CSV="$CSV_DIR/weight_speedup.csv"

REPEAT="${REPEAT:-10}"
SM="${SM:-86}"  # RTX 3090 = sm_86

echo "[1/3] Build bench_weight (SM=$SM)"
nvcc -O3 -std=c++17 -lineinfo \
  -arch="sm_${SM}" \
  -I"$ROOT_DIR/include" \
  "$ROOT_DIR/src/bench_weight.cu" -o "$BIN" \
  |& tee "$LOG_DIR/build.log"

echo "[2/3] Run weight benchmarks (repeat=$REPEAT)"

mapfile -t EDGE_FILES < <(find "$ROOT_DIR/data" -maxdepth 1 -type f -name 'grid_*x*.edges' | sort)

if [[ ${#EDGE_FILES[@]} -eq 0 ]]; then
  echo "No grid_*.edges files found under $ROOT_DIR/data" >&2
  exit 1
fi

: > "$OUT_CSV"

for f in "${EDGE_FILES[@]}"; do
  base="$(basename "$f")"
  dataset="${base%.edges}"

  # Skip tiny/demo cases
  if [[ "$dataset" == "grid_10x10" || "$dataset" == "grid_20x20" || "$dataset" == "grid_40x40" ]]; then
    continue
  fi

  echo "- $dataset"
  "$BIN" --dataset "$dataset" --edges "$f" --repeat "$REPEAT" --out "$OUT_CSV" \
    |& tee "$LOG_DIR/run_${dataset}.log"
done

echo "[3/3] Done. CSV: $OUT_CSV"
