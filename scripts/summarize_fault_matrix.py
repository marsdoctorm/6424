#!/usr/bin/env python3
import collections
import csv
import sys
from pathlib import Path


def summarize(path: Path) -> None:
    counts = collections.Counter()
    total = 0
    with path.open(newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            total += 1
            counts[row["result"]] += 1
    if total == 0:
        print("[WARN] No rows to summarize")
        return
    print(f"[INFO] Fault matrix rows: {total}")
    for k in sorted(counts.keys()):
        pct = counts[k] * 100.0 / total
        print(f"  {k:16s}: {counts[k]:5d} ({pct:5.1f}%)")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: summarize_fault_matrix.py <csv_path>")
        return 1
    path = Path(argv[1])
    if not path.is_file():
        print(f"[ERR] CSV not found: {path}")
        return 1
    summarize(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
