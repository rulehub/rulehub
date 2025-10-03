#!/usr/bin/env python3
"""Increment compliance map `version` fields for maps changed since a git tag.

Usage:
  python tools/increment_map_versions.py --base-tag v0.1.0 [--target main] [--apply]

By default this is a dry-run and will print a markdown summary plus proposed YAML diffs.
Use --apply to write updated map files (simple YAML rewrite using safe_dump).

The script compares the file at <base_tag>:compliance/maps/*.yml with the working tree
version (or target ref via git show) and for any changed map will increment the numeric
`version` (if integer) or bump the patch segment of a semver-like string (x.y.z).
It also enumerates added and removed policy ids per map (across all sections).
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

import yaml


MAPS_DIR = Path("compliance/maps")


def git_show(ref: str, path: str) -> str | None:
    try:
        out = subprocess.check_output(["git", "show", f"{ref}:{path}"], stderr=subprocess.DEVNULL)
        return out.decode("utf-8")
    except subprocess.CalledProcessError:
        return None


def git_changed_files(base: str, target: str) -> List[str]:
    # list files changed between base and target (inclusive diff range base..target)
    cmd = ["git", "diff", "--name-only", f"{base}..{target}"]
    out = subprocess.check_output(cmd)
    return [line for line in out.decode("utf-8").splitlines() if line]


def load_yaml_from_text(text: str) -> dict:
    return yaml.safe_load(text) or {}


def collect_policy_ids_from_map(data: dict) -> Set[str]:
    ids: Set[str] = set()
    sections = data.get("sections") or {}
    for val in sections.values():
        for pid in (val or {}).get("policies") or []:
            ids.add(pid)
    return ids


def bump_version(old) -> Tuple[object, bool]:
    """Return (new_version, bumped_flag).

    - if int -> increment
    - if str semver (x.y.z) -> bump patch
    - if missing or other -> set to 1
    """
    if isinstance(old, int):
        return old + 1, True
    if isinstance(old, str):
        parts = old.split(".")
        if all(p.isdigit() for p in parts):
            # bump last
            parts[-1] = str(int(parts[-1]) + 1)
            return ".".join(parts), True
    # fallback
    return 1, True


def render_markdown_summary(changes: Dict[Path, dict]) -> str:
    lines: List[str] = ["## Compliance maps version bump summary\n"]
    for path, info in sorted(changes.items()):
        lines.append(f"### {path}\n")
        lines.append(f"- old_version: {info.get('old_version')}")
        lines.append(f"- new_version: {info.get('new_version')}")
        added = info.get("added", [])
        removed = info.get("removed", [])
        if added:
            lines.append(f"- Added policies ({len(added)}):")
            for p in added:
                lines.append(f"  - {p}")
        else:
            lines.append("- Added policies: none")
        if removed:
            lines.append(f"- Removed policies ({len(removed)}):")
            for p in removed:
                lines.append(f"  - {p}")
        else:
            lines.append("- Removed policies: none")
        lines.append("")
    return "\n".join(lines)


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-tag", required=True, help="Base git tag or ref to compare from")
    parser.add_argument("--target", default="main", help="Target ref to compare to (default: main)")
    parser.add_argument("--apply", action="store_true", help="Write updated map files")
    args = parser.parse_args(argv)

    base = args.base_tag
    target = args.target

    # ensure base tag exists
    try:
        subprocess.check_call(
            ["git", "rev-parse", "--verify", base], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except subprocess.CalledProcessError:
        print(f"Base tag/ref '{base}' not found. Create it or choose an existing tag.", file=sys.stderr)
        return 2

    changed = git_changed_files(base, target)
    map_changes: Dict[Path, dict] = {}
    for f in changed:
        p = Path(f)
        if p.is_relative_to(MAPS_DIR):
            # load old and new
            old_text = git_show(base, f) or ""
            new_text = p.read_text(encoding="utf-8") if p.exists() else ""
            old_yaml = load_yaml_from_text(old_text) if old_text else {}
            new_yaml = load_yaml_from_text(new_text) if new_text else {}
            old_ids = collect_policy_ids_from_map(old_yaml)
            new_ids = collect_policy_ids_from_map(new_yaml)
            added = sorted(new_ids - old_ids)
            removed = sorted(old_ids - new_ids)

            old_version = old_yaml.get("version")
            new_version_candidate, bumped = bump_version(new_yaml.get("version", old_version))

            map_changes[p] = {
                "old_version": old_version,
                "new_version": new_version_candidate,
                "added": added,
                "removed": removed,
                "old_yaml": old_yaml,
                "new_yaml": new_yaml,
            }

    if not map_changes:
        print("No compliance maps changed between %s and %s." % (base, target))
        return 0

    md = render_markdown_summary(map_changes)
    print(md)

    for path, info in map_changes.items():
        new_yaml = info["new_yaml"]
        new_yaml["version"] = info["new_version"]
        if args.apply:
            # write back
            out = yaml.safe_dump(new_yaml, sort_keys=False, allow_unicode=True)
            path.write_text(out, encoding="utf-8")
            print(f"WROTE: {path}")
        else:
            print(f"--- Proposed change for {path} ---")
            print(f"version: {info.get('old_version')} -> {info.get('new_version')}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
