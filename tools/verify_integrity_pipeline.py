#!/usr/bin/env python3
"""Aggregate integrity verification for RuleHub supply‑chain artifacts.

Goals:
  * Single entrypoint performing holistic integrity verification across:
      - Bundle manifest (dist/opa-bundle.manifest.json)
      - Bundle tarball (dist/opa-bundle.tar.gz)
      - Dist manifest (dist/dist.manifest.json)
  * Recompute per‑file sha256 + size and compare.
  * Recompute aggregate_hash fields and compare.
  * Cross‑checks:
      - build_commit consistency between manifests
      - dist manifest must include the bundle tarball & bundle manifest
      - bundle manifest policy entries must correspond to actual files on disk
      - each bundle policy file must also be present inside the bundle tarball
  * Produce concise status table and exit non‑zero on any error.

This script intentionally overlaps logic in verify_bundle.py and
verify_dist_manifest.py to provide a single high‑signal gate suitable for CI.

Exit codes: 0 OK, 1 validation failure, 2 usage error / missing inputs.

Usage:
  python tools/verify_integrity_pipeline.py \
      --bundle-manifest dist/opa-bundle.manifest.json \
      --dist-manifest dist/dist.manifest.json \
      --bundle dist/opa-bundle.tar.gz \
      --policies-root policies
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import tarfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List


BUNDLE_REQUIRED = {"schema_version", "build_commit",
                   "build_time", "policies", "aggregate_hash"}
DIST_REQUIRED = {"schema_version", "build_commit",
                 "build_time", "artifacts", "aggregate_hash"}
POLICY_KEYS = {"path", "sha256", "bytes"}
ARTIFACT_KEYS = {"path", "sha256", "bytes"}


@dataclass
class Issue:
    scope: str   # which component (bundle-manifest, dist-manifest, cross)
    level: str   # ERROR / WARN / INFO
    message: str

    def __str__(self) -> str:  # pragma: no cover - trivial
        return f"[{self.level}] {self.scope}: {self.message}"


def sha256_file(p: Path) -> tuple[str, int]:
    h = hashlib.sha256()
    size = 0
    with p.open('rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
            size += len(chunk)
    return h.hexdigest(), size


def aggregate_hash(items: Iterable[Dict[str, Any]]) -> str:
    lines = [f"{i['sha256']}  {i['path']}" for i in sorted(
        items, key=lambda x: x['path'])]
    data = "\n".join(lines).encode()
    return hashlib.sha256(data).hexdigest()


def load_json(path: Path, scope: str, issues: List[Issue]) -> Dict[str, Any] | None:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        issues.append(Issue(scope, "ERROR", f"file not found: {path}"))
    except json.JSONDecodeError as e:  # pragma: no cover - parse error path
        issues.append(Issue(scope, "ERROR", f"JSON parse error: {e}"))
    return None


def verify_bundle_manifest(
    manifest: Dict[str, Any],
    policies_root: Path,
    bundle_path: Path,
    issues: List[Issue],
) -> None:
    scope = "bundle-manifest"
    missing = BUNDLE_REQUIRED - manifest.keys()
    if missing:
        issues.append(
            Issue(scope, "ERROR", f"missing keys: {sorted(missing)}"))
        return

    raw_policies = manifest.get('policies')
    policies: List[Dict[str, Any]] = raw_policies if isinstance(
        raw_policies, list) else []
    for idx, p in enumerate(policies):
        pk = POLICY_KEYS - p.keys()
        if pk:
            issues.append(
                Issue(scope, "ERROR", f"policies[{idx}] missing keys: {sorted(pk)}"))
            continue
        rel = p['path']
        f = policies_root / rel
        if not f.is_file():
            issues.append(
                Issue(scope, "ERROR", f"missing policy file on disk: {rel}"))
            continue
        sha, size = sha256_file(f)
        if sha != p['sha256']:
            issues.append(Issue(
                scope, "ERROR", f"sha256 mismatch {rel}: manifest {p['sha256']} != actual {sha}"))
        if size != p['bytes']:
            issues.append(Issue(
                scope, "ERROR", f"size mismatch {rel}: manifest {p['bytes']} != actual {size}"))

    # Aggregate hash check
    agg = aggregate_hash(policies)
    if agg != manifest.get('aggregate_hash'):
        issues.append(
            Issue(
                scope,
                "ERROR",
                f"aggregate_hash mismatch: manifest {manifest.get('aggregate_hash')} != recomputed {agg}",
            )
        )

    # Bundle members membership (best-effort)
    if bundle_path.is_file():
        try:
            with tarfile.open(bundle_path, 'r:gz') as tf:
                members = {m.name for m in tf.getmembers() if m.isfile()}
            expected = [p['path'] for p in policies if POLICY_KEYS <= p.keys()]
            missing_in_bundle = [
                p for p in expected if p not in members and p.lstrip('./') not in members
            ]
            if missing_in_bundle:
                issues.append(
                    Issue(
                        scope,
                        "ERROR",
                        f"bundle missing {len(missing_in_bundle)} files (sample={missing_in_bundle[:5]})",
                    )
                )
        except tarfile.ReadError as e:  # pragma: no cover - corrupted tar path
            issues.append(
                Issue(scope, "ERROR", f"unable to read bundle tar: {e}"))
    else:
        issues.append(
            Issue(scope, "ERROR", f"bundle file not found: {bundle_path}"))


def verify_dist_manifest(manifest: Dict[str, Any], dist_dir: Path, issues: List[Issue]) -> None:
    scope = "dist-manifest"
    missing = DIST_REQUIRED - manifest.keys()
    if missing:
        issues.append(
            Issue(scope, "ERROR", f"missing keys: {sorted(missing)}"))
        return
    raw_arts = manifest.get('artifacts')
    artifacts: List[Dict[str, Any]] = raw_arts if isinstance(
        raw_arts, list) else []
    seen = []
    for idx, a in enumerate(artifacts):
        ak = ARTIFACT_KEYS - a.keys()
        if ak:
            issues.append(
                Issue(scope, "ERROR", f"artifacts[{idx}] missing keys: {sorted(ak)}"))
            continue
        rel = a['path']
        f = dist_dir / rel
        if not f.is_file():
            issues.append(Issue(scope, "ERROR", f"missing artifact: {rel}"))
            continue
        sha, size = sha256_file(f)
        seen.append(rel)
        if sha != a['sha256']:
            issues.append(Issue(
                scope, "ERROR", f"sha256 mismatch {rel}: manifest {a['sha256']} != actual {sha}"))
        if size != a['bytes']:
            issues.append(Issue(
                scope, "ERROR", f"size mismatch {rel}: manifest {a['bytes']} != actual {size}"))

    # Aggregate hash
    agg = aggregate_hash(artifacts)
    if agg != manifest.get('aggregate_hash'):
        issues.append(
            Issue(
                scope,
                "ERROR",
                f"aggregate_hash mismatch: manifest {manifest.get('aggregate_hash')} != recomputed {agg}",
            )
        )


def parse_args(argv: List[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description="Holistic integrity verification (bundle + dist)")
    ap.add_argument('--bundle-manifest',
                    default='dist/opa-bundle.manifest.json')
    ap.add_argument('--dist-manifest', default='dist/dist.manifest.json')
    ap.add_argument('--bundle', default='dist/opa-bundle.tar.gz')
    ap.add_argument('--policies-root', default='policies')
    ap.add_argument(
        '--json', help='Optional path to write machine-readable JSON report')
    return ap.parse_args(argv)


def main(argv: List[str]) -> int:
    ns = parse_args(argv)
    issues: List[Issue] = []
    bundle_manifest_path = Path(ns.bundle_manifest)
    dist_manifest_path = Path(ns.dist_manifest)
    bundle_path = Path(ns.bundle)
    policies_root = Path(ns.policies_root)
    dist_dir = dist_manifest_path.parent

    if not policies_root.is_dir():
        print(f"Policies root not found: {policies_root}", file=sys.stderr)
        return 2
    # Load manifests
    bundle_manifest = load_json(
        bundle_manifest_path, 'bundle-manifest', issues)
    dist_manifest = load_json(dist_manifest_path, 'dist-manifest', issues)
    if not bundle_manifest or not dist_manifest:
        # Loading failures recorded as issues; proceed to output
        pass
    else:
        verify_bundle_manifest(
            bundle_manifest, policies_root, bundle_path, issues)
        verify_dist_manifest(dist_manifest, dist_dir, issues)

        # Cross checks
        if bundle_manifest.get('build_commit') != dist_manifest.get('build_commit'):
            issues.append(
                Issue('cross', 'ERROR', 'build_commit mismatch between manifests'))

        # Ensure dist manifest includes the bundle tarball & bundle manifest itself
        dist_artifacts = {a['path']: a for a in dist_manifest.get(
            'artifacts', []) if isinstance(a, dict)}
        for required in [bundle_manifest_path.name, bundle_path.name]:
            if required not in dist_artifacts:
                issues.append(
                    Issue('cross', 'ERROR', f'dist manifest missing artifact entry: {required}'))

    # Summarize
    error_count = sum(1 for i in issues if i.level == 'ERROR')
    warn_count = sum(1 for i in issues if i.level == 'WARN')

    # Table output
    print("Integrity Verification Summary:\n")
    print(f"{'Component':<22} | {'Status'}")
    print("-----------------------|--------")
    components = ['bundle-manifest', 'dist-manifest', 'cross']
    for comp in components:
        comp_errors = any(i.level == 'ERROR' and i.scope ==
                          comp for i in issues)
        comp_warns = any(i.level == 'WARN' and i.scope == comp for i in issues)
        if comp_errors:
            status = 'FAIL'
        elif comp_warns:
            status = 'WARN'
        else:
            status = 'OK'
        print(f"{comp:<22} | {status}")
    print("-----------------------|--------")
    print(f"Errors: {error_count}  Warnings: {warn_count}")

    for i in issues:
        print(i)

    if ns.json:
        report = {
            'errors': error_count,
            'warnings': warn_count,
            'issues': [i.__dict__ for i in issues],
            'bundle_manifest': bundle_manifest_path.as_posix(),
            'dist_manifest': dist_manifest_path.as_posix(),
            'bundle': bundle_path.as_posix(),
        }
        Path(ns.json).write_text(json.dumps(
            report, indent=2, sort_keys=True) + "\n")
        print(f"Wrote JSON report: {ns.json}")

    if error_count:
        print("FAIL: integrity verification failed")
        return 1
    print("OK: integrity verification passed")
    return 0


if __name__ == '__main__':  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
