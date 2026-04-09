#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path


def fmt_int(x: int) -> str:
    return f"{x:,}"


def fmt_ms(x: float) -> str:
    # Keep consistent with existing tables: 3 decimals for ms
    return f"{x:.3f}"


def fmt_x(x: float) -> str:
    return f"{x:.2f}\\times"


def grid_label(n: int) -> str:
    return f"{n}\\times{n}"


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
        raise SystemExit("No rows")

    rows.sort(key=lambda r: int(r["lg_edges"]))

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines = []
    lines.append("\\begin{table}[H]")
    lines.append("    \\centering")
    lines.append("    \\caption{端到端三阶段耗时分解与总耗时对比（CPU vs GPU）}")
    lines.append("    \\label{tab:exp_phase4_overall_breakdown}")
    lines.append("    \\renewcommand{\\arraystretch}{1.15}")
    lines.append("    \\resizebox{0.98\\textwidth}{!}{%")
    lines.append("    \\begin{tabular}{cccccccccc}")
    lines.append("        \\toprule")
    lines.append(
        "        \\textbf{网格规模} & $|V_H|$ & $|E_H|$ & \\textbf{CPU-拓扑} & \\textbf{CPU-权重} & \\textbf{CPU-寻优} & \\textbf{GPU-拓扑} & \\textbf{GPU-权重} & \\textbf{GPU-寻优+传输} & \\textbf{总加速比}\\\\"
    )
    lines.append("        \\midrule")

    for r in rows:
        g = int(r["grid_n"])
        V = int(r["lg_nodes"])
        EH = int(r["lg_edges"])

        topo_cpu = float(r["topo_cpu_ms"])
        weight_cpu = float(r["weight_cpu_ms"])
        sssp_cpu = float(r["sssp_cpu_ms"])

        topo_gpu = float(r["topo_gpu_ms"])
        weight_gpu = float(r["weight_gpu_ms"])
        sssp_gpu = float(r["sssp_gpu_ms"])
        xfer = float(r["transfer_ms"])

        speedup = float(r["speedup_total"])

        gpu_opt_plus_xfer = sssp_gpu + xfer

        lines.append(
            "        "
            + grid_label(g)
            + " & "
            + fmt_int(V)
            + " & "
            + fmt_int(EH)
            + " & "
            + fmt_ms(topo_cpu)
            + " & "
            + fmt_ms(weight_cpu)
            + " & "
            + fmt_ms(sssp_cpu)
            + " & "
            + fmt_ms(topo_gpu)
            + " & "
            + fmt_ms(weight_gpu)
            + " & "
            + fmt_ms(gpu_opt_plus_xfer)
            + " & "
            + fmt_x(speedup)
            + "\\\\"
        )

    lines.append("        \\bottomrule")
    lines.append("    \\end{tabular}}")
    lines.append("\\end{table}")

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[OK] wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
