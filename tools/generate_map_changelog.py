#!/usr/bin/env python3
"""Generate changelog fragment for compliance maps.

Usage examples:
  python tools/generate_map_changelog.py --since-tag v0.1.0
  python tools/generate_map_changelog.py --since-tag v0.1.0 --output dist/compliance_maps_changelog.md

Behavior:
    * For each YAML in compliance/maps/*.yml parses current policy IDs.
    * If --since-tag exists, loads historical version via `git show <tag>:path`.
    * Computes Added (now - then) and Removed (then - now) per map (sorted).
    * If tag missing or file absent at tag, historical set is empty (initial add).
    * If tag not found: treat as initial baseline (all current policies Added) unless --strict.
    * Outputs markdown fragment (stdout and optional --output) without mutating map versions.

Exit codes:
  0 success
  2 strict mode failure (tag missing)
"""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys
from typing import Dict, List, Set


try:
    import yaml  # type: ignore
except ImportError:  # pragma: no cover
    print("PyYAML not installed. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

MAP_DIR = pathlib.Path("compliance/maps")


def git_show(path: pathlib.Path, tag: str) -> str | None:
    """Return file content at tag or None if not present."""
    rel = path.as_posix()
    try:
        out = subprocess.check_output(["git", "show", f"{tag}:{rel}"], stderr=subprocess.STDOUT)
        return out.decode()
    except subprocess.CalledProcessError:
        return None


def parse_map_policies(text: str) -> Set[str]:
    try:
        data = yaml.safe_load(text) or {}
    except yaml.YAMLError:
        return set()
    policies: Set[str] = set()
    sections = data.get("sections") or {}
    if isinstance(sections, dict):
        for sec in sections.values():
            if isinstance(sec, dict):
                for pid in sec.get("policies") or []:
                    if isinstance(pid, str):
                        policies.add(pid.strip())
    return policies


def collect_current() -> Dict[str, Set[str]]:
    result: Dict[str, Set[str]] = {}
    for path in sorted(MAP_DIR.glob("*.yml")):
        result[path.name] = parse_map_policies(path.read_text())
    return result


def build_fragment(since_tag: str | None, current: Dict[str, Set[str]], strict: bool) -> str:
    tag_found = False
    historical: Dict[str, Set[str]] = {}
    if since_tag:
        # See if tag exists
        tag_list = subprocess.check_output(["git", "tag", "--list", since_tag]).decode().strip().splitlines()
        if tag_list and since_tag in tag_list:
            tag_found = True
        elif strict:
            print(f"Tag '{since_tag}' not found and --strict supplied", file=sys.stderr)
            sys.exit(2)

    for map_name, current_set in current.items():
        if tag_found:
            path = MAP_DIR / map_name
            blob = git_show(path, since_tag)  # type: ignore[arg-type]
            if blob is None:
                historical[map_name] = set()
            else:
                historical[map_name] = parse_map_policies(blob)
        else:
            historical[map_name] = set()  # initial baseline scenario

    lines: List[str] = []
    header_tag = since_tag if (since_tag and tag_found) else "<INITIAL>"
    lines.append(f"### Compliance Map Changes Since {header_tag}\n")
    if not tag_found and since_tag:
        lines.append(
            f"_Note: Tag '{since_tag}' not found; treating as initial import "
            f"(all policies currently counted as Added)._"
        )
        lines.append("")
    for map_name in sorted(current):
        cur = current[map_name]
        old = historical.get(map_name, set())
        added = sorted(cur - old)
        removed = sorted(old - cur)
        if not added and not removed:
            # No change (only possible when tag_found True)
            continue
        lines.append(f"#### {map_name}")
        if added:
            lines.append("Added:")
            for a in added:
                lines.append(f"- {a}")
        if removed:
            lines.append("Removed:")
            for r in removed:
                lines.append(f"- {r}")
        lines.append("")
    if len(lines) == 2:  # Only header + blank
        lines.append("No changes detected.")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate compliance map changelog fragment")
    ap.add_argument("--since-tag", help="Git tag to diff against", default=None)
    ap.add_argument("--output", help="Optional output file path")
    ap.add_argument("--strict", action="store_true", help="Fail if tag missing instead of treating as initial")
    args = ap.parse_args()

    current = collect_current()
    fragment = build_fragment(args.since_tag, current, args.strict)
    if args.output:
        out_path = pathlib.Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(fragment)
    sys.stdout.write(fragment)
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
