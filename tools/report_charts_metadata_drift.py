#!/usr/bin/env python3
"""Report policy IDs present in charts but missing local metadata (potential drift).

This script scans a Helm charts directory (the `files/` content from rulehub-charts)
for any Kubernetes YAML object that contains a `metadata.labels.rulehub.id` or
`metadata.annotations.rulehub.id` value and compares that set against the local
metadata IDs discovered under `policies/**/metadata.yaml`.

Output: by default a human‑readable summary listing each drift ID; with --json a
JSON document containing the arrays and counts.

Usage:
  python tools/report_charts_metadata_drift.py --charts-dir ../rulehub-charts/files [--json]

Exit code is always 0 (informational) unless a fatal error occurs (e.g. charts dir
missing), making it safe for advisory CI jobs.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Iterable, Set

import yaml  # type: ignore


try:  # local import (preferred) – tolerate absence if path issues in ad-hoc envs
    from tools.lib.metadata_loader import load_all_metadata  # type: ignore
except Exception:  # pragma: no cover - fallback simple loader

    def load_all_metadata(root_dir: str = "policies"):
        out = []
        root = Path(root_dir)
        for meta in root.rglob("metadata.yaml"):
            try:
                data = yaml.safe_load(meta.read_text(encoding="utf-8")) or {}
            except Exception:
                continue
            if isinstance(data, dict):
                pid = data.get("id") or meta.parent.name
                out.append((pid, meta, data))
        return out


def iter_yaml_documents(path: Path) -> Iterable[dict]:
    """Yield YAML documents from a file; ignore parse errors."""
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
    """Collect rulehub.id values and note duplicates (count occurrences)."""
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


def load_metadata_ids(policies_root: str = "policies") -> Set[str]:
    ids: Set[str] = set()
    for pid, _path, _data in load_all_metadata(policies_root):  # type: ignore
        if isinstance(pid, str) and pid:
            ids.add(pid)
    return ids


def main() -> int:
    ap = argparse.ArgumentParser(description="Report charts policy IDs that lack local metadata (potential drift)")
    ap.add_argument("--charts-dir", required=True, help="Path to rulehub-charts files/ directory")
    ap.add_argument(
        "--policies-root", default="policies", help="Root directory containing policy metadata (default: policies)"
    )
    ap.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    args = ap.parse_args()

    charts_dir = Path(args.charts_dir)
    if not charts_dir.exists():
        print(f"charts directory not found: {charts_dir}", file=sys.stderr)
        return 1
    metadata_ids = load_metadata_ids(args.policies_root)
    chart_ids, dupes = extract_chart_ids(charts_dir)
    # Drift of interest: chart IDs that have no metadata definition locally.
    missing_metadata = sorted(chart_ids - metadata_ids)

    if args.json:
        print(
            json.dumps(
                {
                    "charts_count": len(chart_ids),
                    "metadata_ids_count": len(metadata_ids),
                    "duplicates_in_charts": dupes,
                    "missing_metadata": missing_metadata,
                    "missing_metadata_count": len(missing_metadata),
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    else:
        print(f"[charts-metadata-drift] chart ids: {len(chart_ids)}")
        print(f"[charts-metadata-drift] metadata ids: {len(metadata_ids)}")
        if dupes:
            print("[charts-metadata-drift] duplicate rulehub.id entries detected:")
            for k, v in sorted(dupes.items()):
                print(f"  {k}: {v}")
        print(f"\nPolicy IDs present in charts but missing metadata ({len(missing_metadata)}):")
        for mid in missing_metadata:
            print(f"  - {mid}")
        if not missing_metadata:
            print("  (none)")
    # Advisory only (always return 0 unless prior error).
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
