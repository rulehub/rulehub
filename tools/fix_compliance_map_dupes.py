#!/usr/bin/env python3
"""Detect and fix duplicate policy references in compliance maps.

Rules:
- A policy ID must appear at most once per compliance map (across all sections).
- On --fix, the first occurrence is kept, subsequent duplicates are removed
  (both within the same section and across sections), preserving original order.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple


ROOT = Path(__file__).resolve().parents[1]


def load_yaml(path: Path):
    text = path.read_text(encoding="utf-8")
    # Prefer ruamel.yaml for round-trip preservation
    try:
        from ruamel.yaml import YAML  # type: ignore

        y = YAML(typ="rt")
        y.preserve_quotes = True
        return y.load(text)
    except Exception:
        pass
    # Fallback to PyYAML
    try:
        import yaml as pyyaml  # type: ignore

        return pyyaml.safe_load(text) or {}
    except Exception:
        pass
    print(
        "Missing YAML library. Install one of: ruamel.yaml or PyYAML",
        file=sys.stderr,
    )
    sys.exit(2)


def dump_yaml(path: Path, data) -> None:
    # Prefer ruamel.yaml for round-trip preservation
    try:
        from ruamel.yaml import YAML  # type: ignore

        y = YAML(typ="rt")
        y.preserve_quotes = True
        with path.open("w", encoding="utf-8") as f:
            y.dump(data, f)
        return
    except Exception:
        pass
    # Fallback to PyYAML
    try:
        import yaml as pyyaml  # type: ignore

        with path.open("w", encoding="utf-8") as f:
            pyyaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)
        return
    except Exception:
        pass
    print(
        "Missing YAML library. Install one of: ruamel.yaml or PyYAML",
        file=sys.stderr,
    )
    sys.exit(2)


def collect_map_duplicates(data) -> Tuple[Set[str], Dict[str, List[str]]]:
    """Return (dupes_set, per_section_dupes) for a loaded map object.

    The map structure is expected to follow tools/schemas/compliance-map.schema.json
    with top-level key 'sections' mapping to objects that contain 'policies': [str].
    """
    sections = (data or {}).get("sections") or {}
    seen: Set[str] = set()
    dupes: Set[str] = set()
    per_sec: Dict[str, List[str]] = {}

    for sec_name, sec_val in sections.items():
        pols = (sec_val or {}).get("policies") or []
        if not isinstance(pols, list):
            continue
        local_seen: Set[str] = set()
        for pid in pols:
            if not isinstance(pid, str):
                continue
            if pid in local_seen or pid in seen:
                dupes.add(pid)
                per_sec.setdefault(sec_name, []).append(pid)
            else:
                local_seen.add(pid)
                seen.add(pid)
    return dupes, per_sec


def fix_map_duplicates(data) -> Tuple[int, Set[str]]:
    """Remove duplicate policy ids across the entire map while preserving order.

    Returns (removed_count, removed_ids).
    """
    sections = (data or {}).get("sections") or {}
    global_seen: Set[str] = set()
    removed_ids: Set[str] = set()
    removed_count = 0

    for sec_name, sec_val in sections.items():
        pols = (sec_val or {}).get("policies")
        if not isinstance(pols, list):
            continue
        new_list: List[str] = []
        local_seen: Set[str] = set()
        for pid in pols:
            if not isinstance(pid, str):
                # keep non-string items as-is (defensive)
                new_list.append(pid)
                continue
            if pid in local_seen or pid in global_seen:
                removed_ids.add(pid)
                removed_count += 1
                continue
            new_list.append(pid)
            local_seen.add(pid)
            global_seen.add(pid)
        # assign back only if changed
        if new_list != pols:
            sec_val["policies"] = new_list
    return removed_count, removed_ids


def main() -> int:
    parser = argparse.ArgumentParser(description="Detect and fix duplicate policies in compliance maps")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="Only check for duplicates")
    mode.add_argument("--fix", action="store_true", help="Remove duplicates in-place")
    parser.add_argument(
        "--dir",
        "--maps-dir",
        dest="maps_dir",
        metavar="PATH",
        help="Directory containing compliance maps (defaults to compliance/maps)",
    )
    args = parser.parse_args()

    # Resolve maps directory
    if args.maps_dir:
        maps_dir = Path(args.maps_dir).expanduser().resolve()
    else:
        cwd_maps = Path.cwd() / "compliance" / "maps"
        maps_dir = cwd_maps if cwd_maps.is_dir() else (ROOT / "compliance" / "maps")

    if not maps_dir.is_dir():
        print(f"Maps directory not found: {maps_dir}", file=sys.stderr)
        return 2

    any_dupes = False
    for mp in sorted(maps_dir.glob("*.yml")):
        data = load_yaml(mp) or {}
        dupes, per_sec = collect_map_duplicates(data)
        if args.check:
            if dupes:
                any_dupes = True
                try:
                    rel = mp.relative_to(ROOT)
                except Exception:
                    rel = mp
                print(f"Duplicate policies in {rel}:")
                for sec, items in per_sec.items():
                    if items:
                        print(f"  section '{sec}': {', '.join(items)}")
        else:  # --fix
            if dupes:
                removed_count, removed_ids = fix_map_duplicates(data)
                if removed_count:
                    dump_yaml(mp, data)
                    try:
                        rel = mp.relative_to(ROOT)
                    except Exception:
                        rel = mp
                    print(f"Fixed {removed_count} duplicate reference(s) in {rel}: " + ", ".join(sorted(removed_ids)))

    if args.check:
        if any_dupes:
            print("Duplicate policies detected. Failing.", file=sys.stderr)
            return 1
        print("No duplicate policies found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
