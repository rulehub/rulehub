#!/usr/bin/env python3
"""Verify that dist/ artifact set matches dist manifest.

Checks:
  1. Manifest exists & JSON parses.
  2. Required keys present.
  3. Each listed artifact exists, size & sha256 match.
  4. No extra files in dist/ (excluding the manifest itself) that are missing from manifest.
  5. aggregate_hash matches recomputed.

Exit codes: 0 OK, 1 validation failure, 2 usage error.

Usage:
  python tools/verify_dist_manifest.py --manifest dist/dist.manifest.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List


REQUIRED_KEYS = {"schema_version", "build_commit",
                 "build_time", "artifacts", "aggregate_hash"}
ARTIFACT_KEYS = {"path", "sha256", "bytes"}


@dataclass
class Issue:
    level: str  # ERROR / WARN
    message: str

    def __str__(self) -> str:  # pragma: no cover - trivial
        return f"[{self.level}] {self.message}"


def sha256_file(p: Path) -> tuple[str, int]:
    h = hashlib.sha256()
    size = 0
    with p.open('rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
            size += len(chunk)
    return h.hexdigest(), size


def aggregate_hash(items: List[Dict[str, Any]]) -> str:
    lines = [f"{i['sha256']}  {i['path']}" for i in sorted(
        items, key=lambda x: x['path'])]
    data = "\n".join(lines).encode()
    return hashlib.sha256(data).hexdigest()


def parse_args(argv: List[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument('--manifest', default='dist/dist.manifest.json')
    ap.add_argument('--dist-dir', default='dist')
    ap.add_argument('--allow-extra', action='store_true',
                    help='Do not fail on extra dist files')
    ap.add_argument('--all', action='store_true', help='Accumulate all issues')
    return ap.parse_args(argv)


def main(argv: List[str]) -> int:
    ns = parse_args(argv)
    manifest_path = Path(ns.manifest)
    dist_dir = Path(ns.dist_dir)
    if not manifest_path.is_file():
        print(f"Manifest not found: {manifest_path}", file=sys.stderr)
        return 2
    if not dist_dir.is_dir():
        print(f"Dist dir not found: {dist_dir}", file=sys.stderr)
        return 2

    try:
        manifest = json.loads(manifest_path.read_text())
    except json.JSONDecodeError as e:  # pragma: no cover - parse error path
        print(f"Manifest JSON parse error: {e}", file=sys.stderr)
        return 1

    issues: List[Issue] = []
    missing = REQUIRED_KEYS - manifest.keys()
    if missing:
        issues.append(
            Issue('ERROR', f'Manifest missing keys: {sorted(missing)}'))
        if not ns.all:
            print('\n'.join(map(str, issues)))
            return 1

    artifacts = manifest.get('artifacts') if isinstance(
        manifest.get('artifacts'), list) else []
    for i, art in enumerate(artifacts):
        ak = ARTIFACT_KEYS - art.keys()
        if ak:
            issues.append(
                Issue('ERROR', f'artifacts[{i}] missing keys: {sorted(ak)}'))
            if not ns.all:
                print('\n'.join(map(str, issues)))
                return 1

    # Verify each artifact
    seen: List[str] = []
    for art in artifacts:
        rel = art['path']
        f = dist_dir / rel
        if not f.is_file():
            issues.append(Issue('ERROR', f'Missing artifact file: {rel}'))
            if not ns.all:
                print('\n'.join(map(str, issues)))
                return 1
            continue
        sha, size = sha256_file(f)
        seen.append(rel)
        if sha != art['sha256']:
            issues.append(
                Issue('ERROR', f'Hash mismatch {rel}: manifest {art["sha256"]} != actual {sha}'))
            if not ns.all:
                print('\n'.join(map(str, issues)))
                return 1
        if size != art['bytes']:
            issues.append(
                Issue('ERROR', f'Size mismatch {rel}: manifest {art["bytes"]} != actual {size}'))
            if not ns.all:
                print('\n'.join(map(str, issues)))
                return 1

    # Extra files check
    if not ns.allow_extra:
        disk_files = [p.name for p in dist_dir.iterdir(
        ) if p.is_file() and p.name != manifest_path.name]
        extras = sorted(set(disk_files) - set(seen))
        if extras:
            issues.append(
                Issue('ERROR', f'Extra dist files not in manifest: {extras[:10]}'))
            if not ns.all:
                print('\n'.join(map(str, issues)))
                return 1

    # Aggregate hash
    agg = aggregate_hash(artifacts)
    if agg != manifest.get('aggregate_hash'):
        issues.append(
            Issue(
                'ERROR',
                'aggregate_hash mismatch: manifest {} != recomputed {}'.format(
                    manifest.get('aggregate_hash'), agg
                ),
            )
        )
        if not ns.all:
            print('\n'.join(map(str, issues)))
            return 1

    error_count = sum(1 for i in issues if i.level == 'ERROR')
    for i in issues:
        print(i)
    if error_count:
        print(f'FAIL: {error_count} error(s)')
        return 1
    print('OK: dist manifest verified')
    return 0


if __name__ == '__main__':  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
