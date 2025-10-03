#!/usr/bin/env python3
"""Aggregate daily link audit history CSV files into weekly metrics.

Reads one or more history CSV files matching a glob pattern (default:
`links_audit_history*.csv`) which are expected to have the schema:

    date,non_https,vendor,tracking_query,celex_pdf,long,highly_shared,external_source_code

The first column is an ISO date (YYYY-MM-DD). Remaining columns are integer counts.

The script groups rows by ISO week (ISO year + week number) and produces an
aggregate CSV `links_audit_weekly.csv` with the following columns:

    week,days,<cat>_sum,<cat>_avg,... (for each category in the source header)

Where:
  * week:       ISO week identifier (e.g. 2025-W35)
  * days:       Number of distinct days contributing data to the week
  * <cat>_sum:  Sum of daily counts across the week
  * <cat>_avg:  Arithmetic mean (sum / days) rounded to 2 decimal places

If multiple history files contain the same date, the first occurrence wins and
duplicates are ignored (a warning is printed to stderr).

Usage:
    python tools/aggregate_link_history.py \
        --pattern 'links_audit_history*.csv' \
        --output links_audit_weekly.csv

Exit codes:
  0 success (file written)
  1 no input files found
  2 malformed rows encountered (continues aggregation unless ALL rows bad)
"""

from __future__ import annotations

import argparse
import csv
import glob
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Dict, List, Sequence


@dataclass
class DailyRow:
    day: date
    counts: Dict[str, int]


def parse_history_file(path: Path) -> List[DailyRow]:
    rows: List[DailyRow] = []
    try:
        with path.open("r", encoding="utf-8", newline="") as f:
            reader = csv.reader(f)
            header: List[str] = []
            for i, r in enumerate(reader):
                if i == 0:
                    header = [h.strip() for h in r]
                    if not header or header[0] != "date":
                        print(f"[warn] {path}: unexpected/missing header; skipping file", file=sys.stderr)
                        return []
                    continue
                if not r or not r[0]:
                    continue
                try:
                    d = date.fromisoformat(r[0])
                except Exception:  # pragma: no cover - defensive
                    print(f"[warn] {path}: bad date '{r[0]}' (row {i + 1}); skipping row", file=sys.stderr)
                    continue
                counts: Dict[str, int] = {}
                for col, val in zip(header[1:], r[1:]):
                    try:
                        counts[col] = int(val)
                    except Exception:
                        print(
                            f"[warn] {path}: non-integer value '{val}' for column '{col}' (row {i + 1}); treating as 0",
                            file=sys.stderr,
                        )
                        counts[col] = 0
                # Fill any header columns missing in row with 0
                for col in header[1:]:
                    counts.setdefault(col, 0)
                rows.append(DailyRow(d, counts))
    except FileNotFoundError:
        return []
    return rows


def aggregate_weekly(rows: Sequence[DailyRow]) -> Dict[str, Dict[str, float]]:
    """Return mapping week_id -> aggregated metrics.

    For each category: store sum and avg (computed later when writing).
    """
    weekly: Dict[str, Dict[str, float]] = {}
    # Determine full category set
    categories: List[str] = []
    for r in rows:
        for k in r.counts.keys():
            if k not in categories:
                categories.append(k)
    for r in rows:
        iso = r.day.isocalendar()  # (year, week, weekday)
        week_id = f"{iso[0]}-W{iso[1]:02d}"
        w = weekly.setdefault(week_id, {"_days": 0})
        if w["_days"] == 0:  # initialize per-category sums
            for c in categories:
                w.setdefault(f"{c}_sum", 0.0)
        w["_days"] += 1
        for c in categories:
            w[f"{c}_sum"] += float(r.counts.get(c, 0))
    return weekly


def write_weekly_csv(path: Path, weekly: Dict[str, Dict[str, float]], categories: Sequence[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    header: List[str] = ["week", "days"]
    for c in categories:
        header.append(f"{c}_sum")
        header.append(f"{c}_avg")
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for week in sorted(weekly.keys()):
            data = weekly[week]
            days = int(data.get("_days", 0)) or 1
            row: List[str] = [week, str(days)]
            for c in categories:
                total = data.get(f"{c}_sum", 0.0)
                avg = total / days if days else 0.0
                row.append(str(int(total)))
                row.append(f"{avg:.2f}")
            writer.writerow(row)


def main() -> int:
    ap = argparse.ArgumentParser(description="Aggregate daily link audit history into weekly CSV")
    ap.add_argument(
        "--pattern",
        default="links_audit_history*.csv",
        help="Glob pattern for history CSV files (default: links_audit_history*.csv)",
    )
    ap.add_argument(
        "--output",
        default="links_audit_weekly.csv",
        help="Output CSV path (default: links_audit_weekly.csv)",
    )
    args = ap.parse_args()

    files = sorted(glob.glob(args.pattern))
    if not files:
        print(f"[aggregate] no files matched pattern: {args.pattern}", file=sys.stderr)
        return 1
    all_rows: List[DailyRow] = []
    seen_dates = set()
    categories_order: List[str] = []
    for fp in files:
        for r in parse_history_file(Path(fp)):
            if r.day in seen_dates:
                # Duplicate date across files — skip
                print(f"[warn] duplicate date {r.day} in {fp}; ignoring", file=sys.stderr)
                continue
            seen_dates.add(r.day)
            for k in r.counts:
                if k not in categories_order:
                    categories_order.append(k)
            all_rows.append(r)
    if not all_rows:
        print("[aggregate] no valid rows parsed", file=sys.stderr)
        return 1
    weekly = aggregate_weekly(all_rows)
    write_weekly_csv(Path(args.output), weekly, categories_order)
    print(f"[aggregate] wrote {args.output} (weeks={len(weekly)})")
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI
    raise SystemExit(main())
