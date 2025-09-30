#!/usr/bin/env python3
"""Compare RuleHub dist/index.json (packages ids) against Helm chart manifests.

Extracts `rulehub.id` from labels or annotations in YAML documents under a charts
`files/` directory and reports drift relative to the generated catalog.

Usage:
  python tools/compare_charts_policies.py --charts-dir ../rulehub-charts/files [--json] [--fail-on-drift]

Outputs human-readable text by default or JSON with --json.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Iterable, Set

import yaml


INDEX_PATH = Path("dist/index.json")


def load_index_ids(index_path: Path) -> Set[str]:
    if not index_path.exists():  # lazy regen attempt
        try:  # pragma: no cover - best effort
            from coverage_map import main as coverage_main  # type: ignore

            coverage_main()
        except Exception:
            pass
    if not index_path.exists():
        raise FileNotFoundError(f"{index_path} not found (run 'make catalog')")
    with open(index_path, "r", encoding="utf-8") as f:
        data = json.load(f) or {}
    pkgs = data.get("packages") or []
    ids: Set[str] = set()
    for p in pkgs:
        if isinstance(p, dict):
            pid = p.get("id")
            if isinstance(pid, str) and pid:
                ids.add(pid)
    return ids


def iter_yaml_documents(path: Path) -> Iterable[dict]:
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return []
    try:
        for doc in yaml.safe_load_all(text):
            if isinstance(doc, dict):
                yield doc
    except yaml.YAMLError:
        return []


def extract_chart_ids(charts_dir: Path) -> tuple[Set[str], dict[str, int]]:
    ids: Set[str] = set()
    dupes: dict[str, int] = {}
    for yfile in charts_dir.rglob("*.y*ml"):
        for doc in iter_yaml_documents(yfile):
            meta = doc.get("metadata") if isinstance(doc, dict) else None
            if not isinstance(meta, dict):
                continue
            rid = None
            for field in ("labels", "annotations"):
                src = meta.get(field)
                if isinstance(src, dict) and src.get("rulehub.id"):
                    rid = str(src.get("rulehub.id")).strip()
                    break
            if rid:
                if rid in ids:
                    dupes[rid] = dupes.get(rid, 1) + 1
                ids.add(rid)
    return ids, dupes


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Compare dist/index.json vs chart manifests for rulehub.id drift")
    ap.add_argument("--charts-dir", required=True,
                    help="Path to chart files/ directory")
    ap.add_argument("--json", action="store_true",
                    help="Emit JSON instead of text")
    ap.add_argument("--fail-on-drift", action="store_true",
                    help="Exit 2 if any drift detected")
    args = ap.parse_args()

    charts_dir = Path(args.charts_dir)
    if not charts_dir.exists():
        print(f"charts directory not found: {charts_dir}", file=sys.stderr)
        return 1
    try:
        index_ids = load_index_ids(INDEX_PATH)
    except Exception as e:  # pragma: no cover - simple error path
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    chart_ids, dupes = extract_chart_ids(charts_dir)
    missing_in_charts = sorted(index_ids - chart_ids)
    extra_in_charts = sorted(chart_ids - index_ids)
    if args.json:
        print(json.dumps({
            "missing_in_charts": missing_in_charts,
            "extra_in_charts": extra_in_charts,
            "index_count": len(index_ids),
            "charts_count": len(chart_ids),
            "chart_duplicates": dupes,
        }, indent=2, ensure_ascii=False))
    else:
        print(f"[charts-drift] index ids: {len(index_ids)}")
        print(f"[charts-drift] chart ids: {len(chart_ids)}")
        if dupes:
            print("[charts-drift] duplicate chart ids:")
            for k, v in sorted(dupes.items()):
                print(f"  {k}: {v}")
        print("\nMissing in charts (present only in index):",
              len(missing_in_charts))
        for mid in missing_in_charts:
            print(f"  + {mid}")
        print("\nExtra in charts (not in index):", len(extra_in_charts))
        for eid in extra_in_charts:
            print(f"  - {eid}")
    drift = bool(missing_in_charts or extra_in_charts)
    if drift and args.fail_on_drift:
        return 2
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
