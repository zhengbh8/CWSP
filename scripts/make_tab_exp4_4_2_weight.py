#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path


def fmt_int(x: int) -> str:
    return f"{x:,}"


def fmt_ms(x: float, digits: int = 2) -> str:
    return f"{x:.{digits}f}"


def fmt_speedup(x: float) -> str:
    return f"{x:.1f}$\\times$"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    rows = []
    with open(args.csv, "r", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)

    if not rows:
        raise SystemExit("No rows in CSV")

    # Sort by eh
    rows.sort(key=lambda r: int(r["eh"]))

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines = []
    lines.append("\\begin{table}[H]")
    lines.append("    \\centering")
    lines.append("    \\caption{伴随边条件权重计算：SIMT 线程束架构级优化前后性能对比}")
    lines.append("    \\label{tab:exp_phase2_weight}")
    lines.append("    \\renewcommand{\\arraystretch}{1.3}")
    lines.append("    \\resizebox{\\textwidth}{!}{")
    lines.append("    \\begin{tabular}{ccccc}")
    lines.append("        \\toprule")
    lines.append("        \\textbf{线图状态伴随边数 ($|E_H|$)} & \\textbf{CPU 顺序解析 (ms)} & \\textbf{GPU 朴素计算 (ms)} & \\textbf{GPU SIMT 谓词对齐 (ms)} & \\textbf{绝对加速比} \\\\")
    lines.append("        \\midrule")

    for r in rows:
        eh = int(r["eh"])
        cpu_ms = float(r["cpu_ms"])
        gpu_naive_ms = float(r["gpu_naive_ms"])
        gpu_simt_ms = float(r["gpu_simt_ms"])
        speedup = float(r["speedup"])

        # More precision for GPU times when small
        gpu_digits = 3 if min(gpu_naive_ms, gpu_simt_ms) < 10 else 2

        lines.append(
            f"        {fmt_int(eh)} & {fmt_ms(cpu_ms, 2)} & {fmt_ms(gpu_naive_ms, gpu_digits)} & {fmt_ms(gpu_simt_ms, gpu_digits)} & {fmt_speedup(speedup)} \\\\"  # noqa: E501
        )

    lines.append("        \\bottomrule")
    lines.append("    \\end{tabular}")
    lines.append("    }")
    lines.append("\\end{table}")

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[OK] Wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
