# CUDA Experiment Workspace

This repository serves as a workspace for CUDA experiments on the remote server.
Project root is expected to be `/root/autodl-tmp/cwsp`.

## Directory Structure
- `src/`: Source code (`.cu`, `.c`, `.cpp` files).
- `include/`: Header files (`.h`, `.cuh`).
- `data/`: Datasets and input files.
- `results/`: Output results, experiment outputs.
- `scripts/`: Shell scripts for running and building.
- `logs/`: Compilation and execution logs.
- `build/`: Compiled binaries.

## Getting Started

### Minimal Run Workflow
To start working, simply run the following commands:
```bash
chmod +x scripts/*.sh

# 1. Collect Environment Info
./scripts/collect_env.sh

# 2. Compile and Run Hello World
./scripts/run_hello.sh
```

### Outputs
- **Environment**: Check `results/env.txt`
- **Build Logs & Output**: Check `logs/hello.log`
- **Executables**: Check `build/` directory
