#!/usr/bin/env python3
"""Compare current link audit report against a stored baseline.

Reads a baseline JSON file (typically committed or manually curated) and a
freshly generated current JSON report (from analyze_links.py) and outputs a
concise drift summary per suspicious category.

Baseline file: links_audit_baseline.json (default)
Current file:  links_audit_report.json (default)

For each category (non_https, vendor, tracking_query, celex_pdf, long) it
computes:
  * added   (present now, absent before)
  * removed (present before, absent now)

It prints a tabular summary with counts plus overall totals. Optionally lists
the first few added/removed URLs for quick inspection (truncated for brevity).

Exit codes:
  0  success (no drift or drift ignored)
  6  drift detected AND FAIL_LINK_AUDIT=1

If the baseline file does not exist, a notice is printed and exit status 0 is
returned (establish a baseline by copying the current report if desired).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Set


CATEGORIES = ["non_https", "vendor", "tracking_query", "celex_pdf", "long"]


def load_json(path: Path) -> Dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:  # pragma: no cover - defensive
        print(
            f"[links-baseline-diff] failed reading {path}: {e}", file=sys.stderr)
        return {}


def extract_category_sets(report: Dict[str, Any]) -> Dict[str, Set[str]]:
    susp = report.get("suspicious", {}) if isinstance(report, dict) else {}
    out: Dict[str, Set[str]] = {}
    for cat in CATEGORIES:
        urls = susp.get(cat, [])
        if isinstance(urls, list):
            out[cat] = {u for u in urls if isinstance(u, str)}
        else:
            out[cat] = set()
    return out


def summarize_diff(base_sets: Dict[str, Set[str]], cur_sets: Dict[str, Set[str]]):
    summary = {}
    total_added = 0
    total_removed = 0
    for cat in CATEGORIES:
        base = base_sets.get(cat, set())
        cur = cur_sets.get(cat, set())
        added = sorted(cur - base)
        removed = sorted(base - cur)
        total_added += len(added)
        total_removed += len(removed)
        summary[cat] = {
            "added": added,
            "removed": removed,
            "added_count": len(added),
            "removed_count": len(removed),
        }
    summary["totals"] = {
        "added": total_added,
        "removed": total_removed,
    }
    return summary


def render(summary: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append("Link Audit Baseline Diff:")
    lines.append("category | added | removed")
    lines.append("---------|-------|--------")
    for cat in CATEGORIES:
        c = summary[cat]
        lines.append(f"{cat} | {c['added_count']} | {c['removed_count']}")
    totals = summary["totals"]
    lines.append(f"TOTAL | {totals['added']} | {totals['removed']}")
    # Provide brief examples if drift
    for cat in CATEGORIES:
        c = summary[cat]
        if c["added_count"]:
            sample = ", ".join(c["added"][:5])
            if c["added_count"] > 5:
                sample += " ..."
            lines.append(f"  {cat} added: {sample}")
        if c["removed_count"]:
            sample = ", ".join(c["removed"][:5])
            if c["removed_count"] > 5:
                sample += " ..."
            lines.append(f"  {cat} removed: {sample}")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Compare link audit baseline vs current report")
    ap.add_argument(
        "--baseline",
        default="links_audit_baseline.json",
        help="Baseline JSON file (default: links_audit_baseline.json)",
    )
    ap.add_argument(
        "--current",
        default="links_audit_report.json",
        help="Current report JSON file (default: links_audit_report.json)",
    )
    ap.add_argument("--json", help="Optional path to write JSON diff summary")
    args = ap.parse_args()

    baseline_path = Path(args.baseline)
    current_path = Path(args.current)

    if not baseline_path.is_file():
        print(
            f"[links-baseline-diff] baseline file '{baseline_path}' not found; "
            "nothing to compare (establish baseline)."
        )
        return 0
    if not current_path.is_file():
        print(
            f"[links-baseline-diff] current report '{current_path}' not found; "
            "run analyze_links first.",
            file=sys.stderr,
        )
        return 0

    baseline = load_json(baseline_path)
    current = load_json(current_path)
    base_sets = extract_category_sets(baseline)
    cur_sets = extract_category_sets(current)
    summary = summarize_diff(base_sets, cur_sets)

    if args.json:
        Path(args.json).write_text(json.dumps(
            summary, indent=2), encoding="utf-8")

    print(render(summary))

    drift = summary["totals"]["added"] + summary["totals"]["removed"]
    if os.environ.get("FAIL_LINK_AUDIT") == "1" and drift > 0:
        print(
            "[links-baseline-diff] FAIL (drift detected: added={} removed={})".format(
                summary["totals"]["added"], summary["totals"]["removed"]
            ),
            file=sys.stderr,
        )
        return 6
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
