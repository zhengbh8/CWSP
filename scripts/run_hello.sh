#!/bin/bash
# Locate project root and cd into it safely
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

mkdir -p build logs
LOG_FILE="logs/hello.log"

echo "======================================" >> "$LOG_FILE"
echo "Timestamp: $(date -Iseconds)" >> "$LOG_FILE"
echo "PWD: $(pwd)" >> "$LOG_FILE"
echo "======================================" >> "$LOG_FILE"

COMPILE_CMD="nvcc src/hello.cu -O3 -o build/hello"
echo "Compiling src/hello.cu..." | tee -a "$LOG_FILE"
echo "$ $COMPILE_CMD" >> "$LOG_FILE"

# Compile the CUDA program
if ! eval "$COMPILE_CMD" >> "$LOG_FILE" 2>&1; then
    echo -e "\nCompilation failed! Check $LOG_FILE for details." | tee -a "$LOG_FILE"
    exit 1
fi

echo "Compilation successful. Running..." | tee -a "$LOG_FILE"
echo "--- Execution Output ---" >> "$LOG_FILE"
./build/hello >> "$LOG_FILE" 2>&1
echo "Execution finished. See results in $LOG_FILE"
exit 0
