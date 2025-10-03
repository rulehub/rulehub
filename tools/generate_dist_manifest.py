#!/usr/bin/env python3
"""Generate manifest of all build artifacts in dist/.

This complements the OPA bundle policy manifest by producing a holistic
artifact inventory for supply‑chain integrity checks.

Fields:
  schema_version: 1
  build_commit: current git HEAD (or unknown)
  build_time: ISO8601 UTC timestamp
  artifacts: list[{path, sha256, bytes}]
  aggregate_hash: sha256 over sorted lines "<sha256>  <path>"

Notes:
  * Excludes the output manifest file itself to avoid recursion.
  * Includes existing bundle manifest, SBOM, indexes, coverage reports, etc.

Usage:
  python tools/generate_dist_manifest.py --output dist/dist.manifest.json
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List


def sha256_file(p: Path) -> tuple[str, int]:
    h = hashlib.sha256()
    size = 0
    with p.open('rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
            size += len(chunk)
    return h.hexdigest(), size


def git_commit() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:  # pragma: no cover - git missing
        return "unknown"


def aggregate_hash(items: List[Dict[str, Any]]) -> str:
    lines = [f"{i['sha256']}  {i['path']}" for i in sorted(items, key=lambda x: x['path'])]
    data = "\n".join(lines).encode()
    return hashlib.sha256(data).hexdigest()


def collect(dist_dir: Path, exclude: set[str]) -> List[Dict[str, Any]]:
    artifacts: List[Dict[str, Any]] = []
    for path in dist_dir.iterdir():
        if not path.is_file():
            continue
        rel = path.name
        if rel in exclude:
            continue
        sha, size = sha256_file(path)
        artifacts.append({"path": rel, "sha256": sha, "bytes": size})
    return artifacts


def parse_args(argv: List[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument('--dist-dir', default='dist')
    ap.add_argument('--output', default='dist/dist.manifest.json')
    ap.add_argument('--schema-version', type=int, default=1)
    return ap.parse_args(argv)


def main(argv: List[str]) -> int:
    ns = parse_args(argv)
    dist_dir = Path(ns.dist_dir)
    if not dist_dir.is_dir():
        print(f"dist directory not found: {dist_dir}", file=sys.stderr)
        return 2
    out_path = Path(ns.output)
    out_name = out_path.name
    artifacts = collect(dist_dir, exclude={out_name})
    manifest: Dict[str, Any] = {
        "schema_version": ns.schema_version,
        "build_commit": git_commit(),
        "build_time": datetime.now(timezone.utc).isoformat(),
        "artifacts": artifacts,
        "aggregate_hash": aggregate_hash(artifacts),
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp = out_path.with_suffix(out_path.suffix + '.tmp')
    tmp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    tmp.replace(out_path)
    print(f"Wrote {out_path} (artifacts={len(artifacts)})")
    return 0


if __name__ == '__main__':  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
