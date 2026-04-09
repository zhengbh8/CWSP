#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--out", required=True, help="Output PNG")
    args = ap.parse_args()

    rows = []
    with open(args.csv, "r", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)

    if not rows:
        raise SystemExit("No rows")

    rows.sort(key=lambda r: int(r["lg_edges"]))
    x = [int(r["lg_edges"]) for r in rows]
    cpu = [float(r["total_cpu_ms"]) for r in rows]
    gpu = [float(r["total_gpu_ms"]) for r in rows]

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fig = plt.figure(figsize=(6.2, 3.2))
    ax = fig.add_subplot(1, 1, 1)

    ax.plot(x, cpu, marker="o", linewidth=1.6, label="CPU total")
    ax.plot(x, gpu, marker="s", linewidth=1.6, label="GPU total")

    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel(r"$|E_H|$ (line-graph edges)")
    ax.set_ylabel("End-to-end time (ms)")
    ax.grid(True, which="both", linestyle="--", linewidth=0.6, alpha=0.6)
    ax.legend(loc="best", frameon=False)

    fig.tight_layout()
    fig.savefig(out_path, dpi=200, bbox_inches="tight")
    print(f"[OK] wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
