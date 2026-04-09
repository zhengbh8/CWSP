#!/usr/bin/env bash
set -euo pipefail

# Run 4.4.1 line-graph topology rebuild benchmark.
# Outputs:
#   cwsp/results/exp4_4_1_topology/topology_speedup.csv
#   cwsp/results/exp4_4_1_topology/topology_speedup.pdf (after plotting)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_DIR="$ROOT_DIR/results/exp4_4_1_topology"
BIN_DIR="$RESULT_DIR/bin"
LOG_DIR="$RESULT_DIR/logs"
CSV_DIR="$RESULT_DIR/csv"

mkdir -p "$BIN_DIR" "$LOG_DIR" "$CSV_DIR"

BIN="$BIN_DIR/bench_topology"
OUT_CSV="$CSV_DIR/topology_speedup.csv"

REPEAT="${REPEAT:-10}"
SM="${SM:-86}"  # RTX 3090 = sm_86

echo "[1/3] Build bench_topology (SM=$SM)"
nvcc -O3 -std=c++17 -lineinfo \
  -arch="sm_${SM}" \
  -I"$ROOT_DIR/include" \
  "$ROOT_DIR/src/bench_topology.cu" -o "$BIN" \
  |& tee "$LOG_DIR/build.log"

echo "[2/3] Run benchmarks (repeat=$REPEAT)"

# Discover datasets: prefer grid_*.edges then any *.edges
mapfile -t EDGE_FILES < <(find "$ROOT_DIR/data" -maxdepth 1 -type f \( -name 'grid_*.edges' -o -name '*.edges' \) | sort)

if [[ ${#EDGE_FILES[@]} -eq 0 ]]; then
  echo "No .edges files found under $ROOT_DIR/data" >&2
  exit 1
fi

# Reset CSV
: > "$OUT_CSV"

for f in "${EDGE_FILES[@]}"; do
  base="$(basename "$f")"
  dataset="${base%.edges}"
  echo "- $dataset"
  "$BIN" --dataset "$dataset" --edges "$f" --repeat "$REPEAT" --out "$OUT_CSV" \
    |& tee "$LOG_DIR/run_${dataset}.log"
done

echo "[3/3] Done. CSV: $OUT_CSV"
