#!/usr/bin/env python3
"""Verify RuleHub OPA bundle integrity against a manifest.

Checks performed (fail fast on first error unless --all):
 1. Manifest JSON schema (required keys).
 2. Git commit in manifest matches current HEAD (unless --skip-git).
 3. Each listed policy file exists, size & sha256 match manifest.
 4. No extra policy files (optional: --allow-extra to skip).
 5. Aggregate hash matches recomputed (sha256 over sorted lines: "<sha256>  <path>").
 6. Bundle tarball exists and contains each policy file path (relative) when extracted tree is inspected in memory.
 7. (Optional) Cosign signature verification of bundle and/or manifest if signatures provided.

Exit codes:
 0 success, 1 validation failure, 2 usage error, 3 missing dependency.

Example:
  python tools/verify_bundle.py \
    --manifest dist/opa-bundle.manifest.json \
    --bundle dist/opa-bundle.tar.gz \
    --policies-root policies \
    --bundle-sig dist/opa-bundle.tar.gz.sig \
    --bundle-cert dist/opa-bundle.tar.gz.pem
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path
from typing import Any, Dict, List, Optional


REQUIRED_MANIFEST_KEYS = {
    "schema_version", "build_commit", "build_time", "policies", "aggregate_hash"}
POLICY_REQUIRED_KEYS = {"path", "sha256", "bytes"}


@dataclasses.dataclass
class Issue:
    level: str  # ERROR / WARN / INFO
    message: str

    def __str__(self) -> str:  # pragma: no cover - trivial
        return f"[{self.level}] {self.message}"


def sha256_file(path: Path) -> tuple[str, int]:
    h = hashlib.sha256()
    size = 0
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
            size += len(chunk)
    return h.hexdigest(), size


def compute_aggregate(policies: List[Dict[str, Any]]) -> str:
    lines = [f"{p['sha256']}  {p['path']}" for p in sorted(
        policies, key=lambda x: x["path"])]
    joined = "\n".join(lines).encode()
    return hashlib.sha256(joined).hexdigest()


def load_manifest(path: Path) -> Dict[str, Any]:
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as e:  # pragma: no cover - parse error path
        raise SystemExit(f"Manifest JSON parse error: {e}")
    return data


def git_head() -> str | None:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return None


def cosign_verify_blob(blob: Path, sig: Path, cert: Optional[Path]) -> tuple[bool, str]:
    if not shutil.which("cosign"):
        return False, "cosign not installed"
    cmd = ["cosign", "verify-blob", str(blob), "--signature", str(sig)]
    if cert:
        cmd += ["--certificate", str(cert)]
    env = os.environ.copy()
    env.setdefault("COSIGN_EXPERIMENTAL", "1")
    try:
        out = subprocess.check_output(
            cmd, stderr=subprocess.STDOUT, text=True, env=env)
        return True, out
    except subprocess.CalledProcessError as e:
        return False, e.output


def verify_bundle_members(bundle_path: Path, expected_paths: List[str]) -> List[str]:
    missing: List[str] = []
    with tarfile.open(bundle_path, "r:gz") as tf:
        members = {m.name for m in tf.getmembers() if m.isfile()}
    for p in expected_paths:
        if p not in members and p.lstrip("./") not in members:
            missing.append(p)
    return missing


def parse_args(argv: List[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description="Verify OPA bundle + manifest integrity")
    ap.add_argument("--manifest", required=True, help="Path to manifest JSON")
    ap.add_argument("--bundle", required=True,
                    help="Path to OPA bundle tar.gz")
    ap.add_argument("--policies-root", default="policies",
                    help="Root directory of policy sources")
    ap.add_argument("--allow-extra", action="store_true",
                    help="Do not fail if extra policy files exist on disk")
    ap.add_argument("--skip-git", action="store_true",
                    help="Skip git commit validation")
    ap.add_argument(
        "--bundle-sig", help="Cosign signature for bundle (optional)")
    ap.add_argument("--bundle-cert",
                    help="Cosign certificate for bundle (optional)")
    ap.add_argument("--manifest-sig",
                    help="Cosign signature for manifest (optional)")
    ap.add_argument("--manifest-cert",
                    help="Cosign certificate for manifest (optional)")
    ap.add_argument("--all", action="store_true",
                    help="Accumulate all issues before exiting")
    return ap.parse_args(argv)


def main(argv: List[str]) -> int:
    ns = parse_args(argv)
    manifest_path = Path(ns.manifest)
    bundle_path = Path(ns.bundle)
    policies_root = Path(ns.policies_root)

    issues: List[Issue] = []

    if not manifest_path.is_file():
        print(f"Manifest not found: {manifest_path}", file=sys.stderr)
        return 2
    if not bundle_path.is_file():
        print(f"Bundle not found: {bundle_path}", file=sys.stderr)
        return 2

    manifest = load_manifest(manifest_path)

    missing_keys = REQUIRED_MANIFEST_KEYS - manifest.keys()
    if missing_keys:
        issues.append(
            Issue("ERROR", f"Manifest missing keys: {sorted(missing_keys)}"))
        if not ns.all:
            print("\n".join(map(str, issues)))
            return 1

    # Policies structure
    policies: List[Dict[str, Any]] = manifest.get(
        "policies", []) if isinstance(manifest.get("policies"), list) else []
    for i, p in enumerate(policies):
        pk = POLICY_REQUIRED_KEYS - p.keys()
        if pk:
            issues.append(
                Issue("ERROR", f"Policy[{i}] missing keys: {sorted(pk)}"))
            if not ns.all:
                print("\n".join(map(str, issues)))
                return 1

    # Git commit
    if not ns.skip_git:
        head = git_head()
        if head and manifest.get("build_commit") and head != manifest["build_commit"]:
            issues.append(Issue(
                "ERROR", f"Git HEAD {head} != manifest build_commit {manifest['build_commit']}"))
            if not ns.all:
                print("\n".join(map(str, issues)))
                return 1
        elif head is None:
            issues.append(Issue("WARN", "Git not available to verify commit"))

    # File-by-file verification
    disk_seen: List[str] = []
    for p in policies:
        rel = p["path"]
        fp = policies_root / rel
        if not fp.is_file():
            issues.append(Issue("ERROR", f"Missing policy file: {rel}"))
            if not ns.all:
                print("\n".join(map(str, issues)))
                return 1
            continue
        sha, size = sha256_file(fp)
        disk_seen.append(rel)
        if sha != p["sha256"]:
            issues.append(
                Issue("ERROR", f"Hash mismatch {rel}: manifest {p['sha256']} != actual {sha}"))
            if not ns.all:
                print("\n".join(map(str, issues)))
                return 1
        if size != p["bytes"]:
            issues.append(
                Issue("ERROR", f"Size mismatch {rel}: manifest {p['bytes']} != actual {size}"))
            if not ns.all:
                print("\n".join(map(str, issues)))
                return 1

    # Extra files detection
    if not ns.allow_extra:
        all_policy_files = [str(p.relative_to(policies_root))
                            for p in policies_root.rglob("metadata.yaml")]
        # Heuristic: we only listed metadata.yaml in manifest (extend later if needed)
        extras = set(all_policy_files) - set(disk_seen)
        if extras:
            issues.append(
                Issue("ERROR", f"Extra policy files not in manifest: {sorted(extras)[:10]}"))
            if not ns.all:
                print("\n".join(map(str, issues)))
                return 1

    # Aggregate hash
    agg = compute_aggregate(policies)
    if agg != manifest.get("aggregate_hash"):
        issues.append(
            Issue(
                "ERROR",
                "aggregate_hash mismatch: manifest {} != recomputed {}".format(
                    manifest.get("aggregate_hash"), agg
                ),
            )
        )
        if not ns.all:
            print("\n".join(map(str, issues)))
            return 1

    # Bundle members
    try:
        missing_in_bundle = verify_bundle_members(
            bundle_path, [p["path"] for p in policies])
        if missing_in_bundle:
            issues.append(
                Issue("ERROR", f"Bundle missing files: {missing_in_bundle[:10]}"))
            if not ns.all:
                print("\n".join(map(str, issues)))
                return 1
    except tarfile.ReadError as e:
        issues.append(Issue("ERROR", f"Bundle unreadable: {e}"))
        if not ns.all:
            print("\n".join(map(str, issues)))
            return 1

    # Optional cosign verification
    # shutil already imported at module top
    if ns.bundle_sig:
        sig = Path(ns.bundle_sig)
        cert = Path(ns.bundle_cert) if ns.bundle_cert else None
        if sig.is_file():
            ok, out = cosign_verify_blob(bundle_path, sig, cert)
            if ok:
                issues.append(
                    Issue("INFO", f"cosign bundle signature OK ({sig.name})"))
            else:
                issues.append(
                    Issue("ERROR", f"cosign bundle signature FAIL: {out.strip()}"))
                if not ns.all:
                    print("\n".join(map(str, issues)))
                    return 1
        else:
            issues.append(
                Issue("WARN", f"Bundle signature file not found: {sig}"))

    if ns.manifest_sig:
        sig = Path(ns.manifest_sig)
        cert = Path(ns.manifest_cert) if ns.manifest_cert else None
        if sig.is_file():
            ok, out = cosign_verify_blob(manifest_path, sig, cert)
            if ok:
                issues.append(
                    Issue("INFO", f"cosign manifest signature OK ({sig.name})"))
            else:
                issues.append(
                    Issue("ERROR", f"cosign manifest signature FAIL: {out.strip()}"))
                if not ns.all:
                    print("\n".join(map(str, issues)))
                    return 1
        else:
            issues.append(
                Issue("WARN", f"Manifest signature file not found: {sig}"))

    # Report
    error_count = sum(1 for i in issues if i.level == "ERROR")
    for i in issues:
        print(i)
    if error_count:
        print(f"FAIL: {error_count} error(s)")
        return 1
    print("OK: bundle integrity verified")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
