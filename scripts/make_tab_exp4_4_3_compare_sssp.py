#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path


def fmt_int(x: int) -> str:
    return f"{x:,}"


def fmt_ms(x: float) -> str:
    # Keep 3 decimals for GPU, 2 for CPU typically; here统一 3 位
    return f"{x:.3f}"


def fmt_speedup(x: float) -> str:
    return f"{x:.2f}\\times"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--out-tex", required=True)
    args = ap.parse_args()

    rows = []
    with open(args.csv, "r", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)

    if not rows:
        raise SystemExit("No rows")

    # Sort by grid_n
    rows.sort(key=lambda r: int(r["grid_n"]))

    out_path = Path(args.out_tex)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Build LaTeX table
    lines = []
    lines.append(r"\begin{table}[H]")
    lines.append(r"    \centering")
    lines.append(r"    \caption{CPU Dijkstra 与 GPU $\Delta$-Stepping 在不同规模线图上的寻优耗时对比}")
    lines.append(r"    \label{tab:exp_phase3_dijkstra_vs_delta}")
    lines.append(r"    \renewcommand{\arraystretch}{1.15}")
    lines.append(r"    \resizebox{0.96\textwidth}{!}{%")
    lines.append(r"    \begin{tabular}{cccccc}")
    lines.append(r"        \toprule")
    lines.append(r"        \textbf{网格规模} & $|V_H|$ & $|E_H|$ & \textbf{CPU Dijkstra (ms)} & \textbf{GPU $\Delta$-Stepping (ms)} & \textbf{加速比}\\")
    lines.append(r"        \midrule")

    for r in rows:
        n = int(r["grid_n"])
        V = int(float(r["V"]))
        EH = int(float(r["EH"]))
        cpu = float(r["cpu_ms"])
        gpu = float(r["gpu_ms"])
        sp = float(r["speedup"])

        lines.append(
            f"        {n}\\times{n} & {fmt_int(V)} & {fmt_int(EH)} & {fmt_ms(cpu)} & {fmt_ms(gpu)} & {fmt_speedup(sp)}\\\\"
        )

    lines.append(r"        \bottomrule")
    lines.append(r"    \end{tabular}}")
    lines.append(r"\end{table}")

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[OK] wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
