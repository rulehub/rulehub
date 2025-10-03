#!/usr/bin/env python3
"""Generate OPA bundle manifest dist/opa-bundle.manifest.json.

Fields:
  schema_version: 1
  build_commit: current git HEAD (or unknown)
  build_time: ISO8601 UTC timestamp
  policies: list of source policy files with sha256 + byte size
  aggregate_hash: sha256 over sorted lines "<sha256>  <path>"

Usage:
  python tools/generate_bundle_manifest.py \
      --policies-root policies \
      --output dist/opa-bundle.manifest.json

Selection:
  Includes all files under policies/ ending in: metadata.yaml, .rego
  (Excludes test rego files if --exclude-tests given.)
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
    except Exception:
        return "unknown"


def aggregate_hash(items: List[Dict[str, Any]]) -> str:
    lines = [f"{i['sha256']}  {i['path']}" for i in sorted(items, key=lambda x: x['path'])]
    data = "\n".join(lines).encode()
    return hashlib.sha256(data).hexdigest()


def collect(policies_root: Path, exclude_tests: bool) -> List[Dict[str, Any]]:
    collected: List[Dict[str, Any]] = []
    for path in policies_root.rglob('*'):
        if not path.is_file():
            continue
        rel = path.relative_to(policies_root).as_posix()
        if exclude_tests and rel.endswith('_test.rego'):
            continue
        if rel.endswith('metadata.yaml') or rel.endswith('.rego'):
            sha, size = sha256_file(path)
            collected.append({"path": rel, "sha256": sha, "bytes": size})
    return collected


def parse_args(argv: List[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument('--policies-root', default='policies')
    ap.add_argument('--output', default='dist/opa-bundle.manifest.json')
    ap.add_argument('--schema-version', type=int, default=1)
    ap.add_argument('--exclude-tests', action='store_true')
    return ap.parse_args(argv)


def main(argv: List[str]) -> int:
    ns = parse_args(argv)
    root = Path(ns.policies_root)
    if not root.is_dir():
        print(f"Policies root not found: {root}", file=sys.stderr)
        return 2
    files = collect(root, ns.exclude_tests)
    out_path = Path(ns.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    commit = git_commit()
    manifest: Dict[str, Any] = {
        "schema_version": ns.schema_version,
        "build_commit": commit,
        "build_time": datetime.now(timezone.utc).isoformat(),
        "policies": files,
        "aggregate_hash": aggregate_hash(files),
    }
    tmp = out_path.with_suffix(out_path.suffix + '.tmp')
    tmp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    tmp.replace(out_path)
    print(f"Wrote {out_path} (policies={len(files)})")
    return 0


if __name__ == '__main__':  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
