#!/bin/bash
# Locate project root and cd into it safely
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

mkdir -p results
OUT_FILE="results/env.txt"

echo "======================================" >> "$OUT_FILE"
echo "Timestamp: $(date -Iseconds)" >> "$OUT_FILE"
echo "PWD: $(pwd)" >> "$OUT_FILE"
echo "======================================" >> "$OUT_FILE"

# Function to run command gracefully without terminating
run_cmd() {
    local cmd="$1"
    echo -e "\n--- $cmd ---" >> "$OUT_FILE"
    
    # Try capturing output and errors. If command not found, we record it.
    if ! eval "$cmd" >> "$OUT_FILE" 2>&1; then
        echo "Note: Command failed or command not found" >> "$OUT_FILE"
    fi
}

run_cmd "nvidia-smi"
run_cmd "nvcc -V"
run_cmd "uname -a"
run_cmd "cat /etc/os-release"
run_cmd "gcc --version"

echo "Environment info collected in $OUT_FILE"
exit 0
