#!/usr/bin/env python3
"""Enforce compliance map version bumps for changed policies.

Given a base git tag/ref (e.g. previous release) this script:

1. Detects changed policy sources (metadata.yaml or policy.rego) in the range
   base..target (default target=HEAD).
2. Derives the affected policy IDs from current working tree metadata.
3. Scans all compliance maps and determines which maps reference any of the
   changed policy IDs.
4. For each such map compares its *version* field at base tag vs current
   working tree. If the value is unchanged (and the base value looked like a
   version we can reason about) the map is flagged as missing a version bump.

Exit status:
  0 = all required bumps present (or only non-versioned maps like 'current').
  1 = one or more maps should have had their version increased.
  2 = usage / git errors.

Notes / heuristics:
  - Maps whose base version is a non-numeric sentinel (e.g. 'current') are
    treated as *informational* only and are not failed (they are listed under
    "unversioned"). This avoids noisy failures while migrating to numeric
    versioning.
  - A version is considered *bumpable* if it is an int, or a dot‑separated
    sequence of integers (simple semver style). Other strings are treated as
    unversioned.

Usage:
  python tools/enforce_map_version_bumps.py --base-tag v0.3.0 [--target main]
  python tools/enforce_map_version_bumps.py --base-tag v0.3.0 --json
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Set

import yaml


MAPS_DIR = Path("compliance/maps")
POLICIES_DIR = Path("policies")


def run(cmd: List[str]) -> str:
    return subprocess.check_output(cmd).decode("utf-8")


def git_changed_files(base: str, target: str) -> List[str]:
    out = run(["git", "diff", "--name-only", f"{base}..{target}"])
    return [line for line in out.splitlines() if line]


def git_show(ref: str, path: str) -> str | None:
    try:
        return run(["git", "show", f"{ref}:{path}"])
    except subprocess.CalledProcessError:
        return None


def is_version_like(val) -> bool:
    if isinstance(val, int):
        return True
    if isinstance(val, str):
        parts = val.split(".")
        return all(p.isdigit() for p in parts)
    return False


def load_current_policy_ids() -> Dict[Path, str]:
    """Map policy directory path -> policy id (from metadata.yaml)."""
    out: Dict[Path, str] = {}
    for meta in POLICIES_DIR.rglob("metadata.yaml"):
        try:
            data = yaml.safe_load(meta.read_text(encoding="utf-8")) or {}
        except Exception:  # pragma: no cover - tolerate bad file
            continue
        if isinstance(data, dict) and data.get("id"):
            out[meta.parent.resolve()] = str(data["id"]).strip()
    return out


def derive_changed_policy_ids(changed_files: List[str], dir_to_id: Dict[Path, str]) -> Set[str]:
    ids: Set[str] = set()
    for f in changed_files:
        if not f.startswith("policies/"):
            continue
        p = Path(f).resolve()
        # policy dir is policies/<domain>/<policy_id>/...
        try:
            # climb until we reach directory containing metadata.yaml we indexed
            cur = p if p.is_dir() else p.parent
            while cur != cur.parent:
                if cur in dir_to_id:
                    ids.add(dir_to_id[cur])
                    break
                cur = cur.parent
        except Exception:
            continue
    return ids


def collect_map_policy_ids(path: Path) -> Set[str]:
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except Exception:
        return set()
    out: Set[str] = set()
    sections = data.get("sections") or {}
    if isinstance(sections, dict):
        for val in sections.values():
            if isinstance(val, dict):
                for pid in val.get("policies") or []:
                    if isinstance(pid, str):
                        out.add(pid.strip())
    return out


def load_map_version(path: Path) -> object:
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except Exception:
        return None
    return data.get("version")


def load_base_map_version(path: Path, base: str):
    txt = git_show(base, str(path))
    if not txt:
        return None
    try:
        data = yaml.safe_load(txt) or {}
    except Exception:
        return None
    return data.get("version")


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description="Ensure compliance maps referencing changed policies have bumped versions")
    ap.add_argument("--base-tag", required=True,
                    help="Base git tag / ref (previous release)")
    ap.add_argument("--target", default="HEAD",
                    help="Target ref to compare to (default: HEAD)")
    ap.add_argument("--json", action="store_true", help="Emit JSON summary")
    args = ap.parse_args(argv)

    # validate base tag
    try:
        subprocess.check_call(
            ["git", "rev-parse", "--verify", args.base_tag],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        print(f"Base tag/ref not found: {args.base_tag}", file=sys.stderr)
        return 2

    changed_files = git_changed_files(args.base_tag, args.target)
    dir_to_id = load_current_policy_ids()
    changed_policy_ids = derive_changed_policy_ids(changed_files, dir_to_id)

    maps_referencing: Dict[str, Dict[str, object]] = {}
    for map_file in MAPS_DIR.glob("*.yml"):
        cur_ids = collect_map_policy_ids(map_file)
        intersection = sorted(changed_policy_ids & cur_ids)
        if not intersection:
            continue
        current_version = load_map_version(map_file)
        base_version = load_base_map_version(map_file, args.base_tag)
        needs_bump = False
        enforceable = is_version_like(
            base_version) and is_version_like(current_version)
        if enforceable and base_version == current_version:
            needs_bump = True
        maps_referencing[str(map_file)] = {
            "changed_policy_ids": intersection,
            "base_version": base_version,
            "current_version": current_version,
            "needs_bump": needs_bump,
            "enforceable": enforceable,
        }

    failing = [m for m, info in maps_referencing.items() if info["needs_bump"]]

    if args.json:
        print(json.dumps({
            "base": args.base_tag,
            "target": args.target,
            "changed_policy_ids_count": len(changed_policy_ids),
            "changed_policy_ids": sorted(changed_policy_ids),
            "maps": maps_referencing,
            "failing_maps": failing,
            "failing_count": len(failing),
        }, ensure_ascii=False, indent=2))
    else:
        print(f"[map-version-bumps] base={args.base_tag} target={args.target}")
        print(f"Changed policy IDs: {len(changed_policy_ids)}")
        for pid in sorted(changed_policy_ids):
            print(f"  - {pid}")
        if not maps_referencing:
            print("No compliance maps reference the changed policies.")
        else:
            print("\nMap status:")
            for m, info in sorted(maps_referencing.items()):
                status = "OK" if not info["needs_bump"] else "MISSING_BUMP"
                if not info["enforceable"]:
                    status = "UNVERSIONED"  # informational only
                print(
                    f"- {m}: base_version={info['base_version']} "
                    f"current_version={info['current_version']} status={status}"
                )
                print("  changed policies:")
                for pid in info["changed_policy_ids"]:  # type: ignore
                    print(f"    * {pid}")
        if failing:
            print("\nMaps missing version bump:")
            for m in failing:
                print(f"  - {m}")

    return 1 if failing else 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
