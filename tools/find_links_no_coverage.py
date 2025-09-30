#!/usr/bin/env python3
"""Report policies that have metadata.links but no compliance map coverage.

Task (Drift & Cross-Repo Sync #4):
    "Compare coverage_by_policy (from coverage.json) with actual links in metadata.links and
    detect any policies lacking coverage."

Logic:
  1. Read dist/coverage.json (produced by coverage_map.py) and collect all policy ids referenced.
  2. Load all metadata.yaml files (via tools.lib.metadata_loader.load_all_metadata).
  3. For each policy with a non-empty links list, if its id is NOT in the coverage set, record it.
  4. Emit a plain text report and a machine-readable JSON (optional) to stdout.

Exit codes:
  0 always (informational only). Non-zero only for usage / missing coverage.json.

Output format (text):
  Header line with counts then table: policy_id | links_count

Environment variables (optional):
  JSON_ONLY=1  -> emit JSON object only (no text table).

JSON structure:
  { "missing_coverage": [ {"id": <policy_id>, "links_count": N} ], "count": C }
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Set, cast

from tools.lib import load_all_metadata  # type: ignore


COVERAGE_JSON = Path("dist/coverage.json")


def load_coverage_ids() -> Set[str]:
    if not COVERAGE_JSON.exists():
        print(
            "[links-no-coverage] coverage.json missing. Run 'make catalog' first.", file=sys.stderr)
        raise SystemExit(1)
    try:
        data = json.loads(COVERAGE_JSON.read_text(encoding="utf-8"))
    except Exception as e:  # pragma: no cover - defensive
        print(
            f"[links-no-coverage] Failed to parse coverage.json: {e}", file=sys.stderr)
        raise SystemExit(1)
    ids: Set[str] = set()
    if not isinstance(data, list):
        return ids
    for reg in data:
        for sec in reg.get("sections", []):
            for pol in sec.get("policies", []):
                pid = pol.get("id")
                if isinstance(pid, str):
                    ids.add(pid)
    return ids


def find_missing(covered: Set[str]) -> List[Dict[str, object]]:
    results: List[Dict[str, object]] = []
    for pid, _path, meta in load_all_metadata():
        links = meta.get("links") or []
        if isinstance(links, dict):  # some older metadata may use mapping style
            # Flatten values if dict form encountered
            flat: List[str] = []
            for v in links.values():
                if isinstance(v, list):
                    flat.extend([str(x) for x in v])
                elif isinstance(v, str):
                    flat.append(v)
            links = flat
        if not isinstance(links, list):
            continue
        links = [link for link in links if isinstance(
            link, str) and link.strip()]
        if not links:
            continue  # only interested in policies that DO have links
        if pid not in covered:
            results.append({"id": pid, "links_count": len(links)})
    # Sort for deterministic output
    results.sort(key=lambda x: x["id"])  # type: ignore[arg-type]
    return results


def main() -> int:
    covered = load_coverage_ids()
    missing = find_missing(covered)
    json_only = os.environ.get("JSON_ONLY") not in (None, "0", "")
    payload = {"missing_coverage": missing, "count": len(missing)}
    if json_only:
        print(json.dumps(payload, indent=2))
        return 0
    print("Policies with metadata.links but NO coverage entries: {}".format(len(missing)))
    if not missing:
        print("(none)")
        return 0
    # Cast because mypy/pylance lose precise type (List[Dict[str, object]])
    width = max(len(cast(str, m["id"])) for m in missing)
    print(f"{'policy_id'.ljust(width)} | links_count")
    print(f"{'-'*width}-+------------")
    for m in missing:
        pid = cast(str, m["id"])  # defensive cast
        print(f"{pid.ljust(width)} | {m['links_count']}")
    # Also emit JSON block at end for machine parsing convenience
    print("\nJSON:")
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
