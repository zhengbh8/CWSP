#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path


def read_csv_map(path: str, key_field: str) -> dict:
    rows = {}
    with open(path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows[r[key_field]] = r
    return rows


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--topo", required=True)
    ap.add_argument("--weight", required=True)
    ap.add_argument("--sssp", required=True)
    ap.add_argument("--xfer", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    topo = read_csv_map(args.topo, "dataset")
    weight = read_csv_map(args.weight, "dataset")
    sssp = read_csv_map(args.sssp, "dataset")
    xfer = read_csv_map(args.xfer, "dataset")

    datasets = sorted(set(topo) & set(weight) & set(sssp) & set(xfer))
    if not datasets:
        raise SystemExit("No overlapping datasets across CSVs")

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fields = [
        "dataset",
        "grid_n",
        "n",
        "m",
        "lg_nodes",
        "lg_edges",
        "topo_cpu_ms",
        "topo_gpu_ms",
        "weight_cpu_ms",
        "weight_gpu_ms",
        "sssp_cpu_ms",
        "sssp_gpu_ms",
        "transfer_ms",
        "total_cpu_ms",
        "total_gpu_ms",
        "speedup_total",
    ]

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for d in datasets:
            t = topo[d]
            w = weight[d]
            s = sssp[d]
            x = xfer[d]

            grid_n = int(s["grid_n"])
            total_cpu = float(t["cpu_ms"]) + float(w["cpu_ms"]) + float(s["cpu_ms"])
            total_gpu = float(t["gpu_ms"]) + float(w["gpu_simt_ms"]) + float(s["gpu_ms"]) + float(x["transfer_ms"])
            speedup = total_cpu / total_gpu

            writer.writerow(
                {
                    "dataset": d,
                    "grid_n": grid_n,
                    "n": int(t["n"]),
                    "m": int(t["m"]),
                    "lg_nodes": int(t["lg_nodes"]),
                    "lg_edges": int(t["lg_edges"]),
                    "topo_cpu_ms": float(t["cpu_ms"]),
                    "topo_gpu_ms": float(t["gpu_ms"]),
                    "weight_cpu_ms": float(w["cpu_ms"]),
                    "weight_gpu_ms": float(w["gpu_simt_ms"]),
                    "sssp_cpu_ms": float(s["cpu_ms"]),
                    "sssp_gpu_ms": float(s["gpu_ms"]),
                    "transfer_ms": float(x["transfer_ms"]),
                    "total_cpu_ms": total_cpu,
                    "total_gpu_ms": total_gpu,
                    "speedup_total": speedup,
                }
            )

    print(f"[OK] wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
