#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_DIR="$ROOT_DIR/results/exp4_4_3_delta"
BIN_DIR="$RESULT_DIR/bin"
LOG_DIR="$RESULT_DIR/logs"
CSV_DIR="$RESULT_DIR/csv"

mkdir -p "$BIN_DIR" "$LOG_DIR" "$CSV_DIR"

BIN="$BIN_DIR/bench_delta_param"
OUT_CSV="$CSV_DIR/delta_ucurve.csv"

SM="${SM:-86}"  # RTX 3090 = sm_86
DATASET_FILE="${DATASET_FILE:-$ROOT_DIR/data/grid_400x400.edges}"
REPEAT="${REPEAT:-5}"

if [[ ! -f "$DATASET_FILE" ]]; then
  echo "Missing dataset file: $DATASET_FILE" >&2
  exit 1
fi

dataset="$(basename "$DATASET_FILE")"
dataset="${dataset%.edges}"

echo "[1/3] Build bench_delta_param (SM=$SM)"
nvcc -O3 -std=c++17 -lineinfo \
  -arch="sm_${SM}" \
  -I"$ROOT_DIR/include" \
  "$ROOT_DIR/src/bench_delta_param.cu" -o "$BIN" \
  |& tee "$LOG_DIR/build.log"

echo "[2/3] Run delta sweep on $dataset"
: > "$OUT_CSV"

"$BIN" --dataset "$dataset" --edges "$DATASET_FILE" --out "$OUT_CSV" \
  --min-delta 5 --max-delta 90 --delta-step 5 --bucket-range 4096 \
  --repeat "$REPEAT" \
  |& tee "$LOG_DIR/run_${dataset}.log"

echo "[3/3] Done. CSV: $OUT_CSV"
