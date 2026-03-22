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

## Repository Visibility / 仓库可见性

> **当前状态：此仓库是 PUBLIC（公开）的，互联网上的任何人都可以查看。**
>
> **Current status: This repository is PUBLIC. Anyone on the internet can view it.**

If you want to restrict access to only yourself:
1. Go to the repository on GitHub: https://github.com/zhengbh8/CWSP
2. Click **Settings** → scroll down to the **Danger Zone** section
3. Click **Change visibility** → select **Make private**

如果你希望仓库只有自己可见：
1. 打开仓库页面：https://github.com/zhengbh8/CWSP
2. 点击 **Settings** → 滚动到底部的 **Danger Zone** 区域
3. 点击 **Change visibility** → 选择 **Make private**

---

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
