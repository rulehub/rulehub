#!/usr/bin/env python3
"""Generate release metrics JSON (dist/release-metrics.json).

Fields:
  policy_count         - total number of policy metadata entries
  map_count            - number of compliance map YAML files
  standards_count      - count of distinct standard values across metadata (metadata['standard'])
  map_version_count    - count of distinct non-empty `version` values across maps
  timestamp            - UTC ISO8601 timestamp
  git_commit           - current HEAD commit hash (short)
  schema_version       - metrics schema version (int, starts at 1)

Usage:
  python tools/generate_release_metrics.py [--output dist/release-metrics.json]

The script purposely relies on the shared metadata loader for caching.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Set

import yaml

from tools.lib import load_all_metadata


DEFAULT_OUTPUT = Path("dist/release-metrics.json")


def collect_policy_metrics(policies_root: str = "policies") -> Dict[str, Any]:
    entries = load_all_metadata(policies_root)
    policy_count = len(entries)
    standards: Set[str] = set()
    for _pid, _path, data in entries:
        std = data.get("standard")
        if isinstance(std, str) and std.strip():
            standards.add(std.strip())
    return {"policy_count": policy_count, "standards_count": len(standards)}


def collect_map_metrics(maps_root: str = "compliance/maps") -> Dict[str, Any]:
    maps_dir = Path(maps_root)
    map_files = sorted([p for p in maps_dir.glob("*.yml") if p.is_file()])
    map_count = len(map_files)
    versions: Set[str] = set()
    for p in map_files:
        try:
            data = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        except Exception:
            continue
        if isinstance(data, dict):
            ver = data.get("version")
            if isinstance(ver, str) and ver.strip():
                versions.add(ver.strip())
    return {"map_count": map_count, "map_version_count": len(versions)}


def git_commit() -> str:
    try:
        return (
            subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], stderr=subprocess.DEVNULL).decode().strip()
        )
    except Exception:
        return "unknown"


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate release metrics JSON")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Output file path")
    args = parser.parse_args()

    metrics: Dict[str, Any] = {"schema_version": 1}
    metrics.update(collect_policy_metrics())
    metrics.update(collect_map_metrics())
    metrics["timestamp"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    metrics["git_commit"] = git_commit()

    out_path = args.output
    if not out_path.parent.exists():
        out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = out_path.with_suffix(out_path.suffix + ".tmp")
    tmp_path.write_text(json.dumps(metrics, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp_path, out_path)
    print(f"Wrote {out_path} ({out_path.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
