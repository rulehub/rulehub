#!/usr/bin/env python3
"""Generate a simplified SLSA-style provenance attestation for the OPA bundle.

Outputs an in-toto Statement JSON (predicateType: slsa.dev/provenance/v0.2) capturing:
  * Subject: dist/opa-bundle.tar.gz (sha256)
  * Build commit (git HEAD) and timestamps
  * Manifest hash (sha256 of dist/opa-bundle.manifest.json)
  * Materials: git repo @ commit, manifest file

Usage:
  python tools/generate_provenance.py \
      --bundle dist/opa-bundle.tar.gz \
      --manifest dist/opa-bundle.manifest.json \
      --output dist/opa-bundle.provenance.json

Environment (optional):
  BUILDER_ID     Override builder.id (default: repo URL if derivable or 'rulehub/local')
  WORKFLOW_REF   Populate predicate.buildType with a workflow ref URL

The script is intentionally minimal (no external deps) and not a full SLSA level implementation.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()


def git_commit() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"


def git_remote_url() -> str | None:
    try:
        url = subprocess.check_output(
            ["git", "remote", "get-url", "origin"], text=True).strip()
        return url
    except Exception:
        return None


def build_statement(
    bundle: Path,
    manifest: Path,
    output: Path,
    builder_id: str | None,
    workflow_ref: str | None,
) -> Dict[str, Any]:
    if not bundle.is_file():
        raise SystemExit(f"Bundle not found: {bundle}")
    if not manifest.is_file():
        raise SystemExit(f"Manifest not found: {manifest}")

    commit = git_commit()
    manifest_sha = sha256_file(manifest)
    bundle_sha = sha256_file(bundle)
    started = datetime.now(timezone.utc)
    finished = datetime.now(timezone.utc)

    remote = git_remote_url() or ""
    if not builder_id:
        # Derive a simple builder ID from remote (if github) else fallback
        if remote.startswith("https://github.com/"):
            builder_id = remote.rstrip('.git')
        else:
            builder_id = "rulehub/local"

    statement: Dict[str, Any] = {
        "_type": "https://in-toto.io/Statement/v0.1",
        "subject": [
            {
                "name": str(bundle),
                "digest": {"sha256": bundle_sha},
            }
        ],
        "predicateType": "https://slsa.dev/provenance/v0.2",
        "predicate": {
            "buildType": workflow_ref or "make://opa-bundle",
            "builder": {"id": builder_id},
            "invocation": {
                "parameters": {"make_target": "opa-bundle"},
                "environment": {},
                "configSource": {
                    "uri": remote or "",
                    "digest": {"sha1": commit},
                    "entryPoint": "Makefile:opa-bundle",
                },
            },
            "metadata": {
                "buildInvocationID": f"{commit[:12]}-{int(started.timestamp())}",
                "buildStartedOn": started.isoformat(),
                "buildFinishedOn": finished.isoformat(),
            },
            "materials": [
                {
                    "uri": remote or "",
                    "digest": {"sha1": commit},
                },
                {
                    "uri": str(manifest),
                    "digest": {"sha256": manifest_sha},
                },
            ],
        },
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_suffix(output.suffix + ".tmp")
    tmp.write_text(json.dumps(statement, indent=2, sort_keys=True) + "\n")
    tmp.replace(output)
    return statement


def parse_args(argv: list[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bundle", default="dist/opa-bundle.tar.gz")
    ap.add_argument("--manifest", default="dist/opa-bundle.manifest.json")
    ap.add_argument("--output", default="dist/opa-bundle.provenance.json")
    return ap.parse_args(argv)


def main(argv: list[str]) -> int:  # pragma: no cover - CLI wrapper
    ns = parse_args(argv)
    builder_id = os.getenv("BUILDER_ID")
    workflow_ref = os.getenv("WORKFLOW_REF")
    stmt = build_statement(Path(ns.bundle), Path(
        ns.manifest), Path(ns.output), builder_id, workflow_ref)
    print(
        f"Wrote {ns.output} (subject sha256={stmt['subject'][0]['digest']['sha256']})")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
