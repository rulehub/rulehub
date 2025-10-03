#!/usr/bin/env python3
"""Normalize `path` field formatting in policy metadata files.

Objective:
  - Find metadata.yaml files where a line is exactly `path:` (empty value) and
    replace it with `path: []` for explicit placeholder semantics.

Usage:
  Dry-run (default):
      python tools/normalize_metadata_paths.py

  Apply in-place edits:
      python tools/normalize_metadata_paths.py --apply

  Show verbose per-file actions:
      python tools/normalize_metadata_paths.py -v

Exit codes:
  0  success (including when no changes needed)
  1  unexpected error

Design notes:
    - Only touches lines that exactly match `^path:\\s*$` (no lists, no existing values).
  - Leaves `path: []` intact (explicit placeholder) and any populated list / scalar untouched.
  - Counts changes; prints a concise summary to stdout.
  - No YAML parsing required; simple line transform keeps risk minimal.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def find_metadata_files(root: Path) -> list[Path]:
    return sorted(root.rglob("metadata.yaml"))


def normalize_file(path: Path, apply: bool, verbose: bool) -> bool:
    """Return True if modified."""
    try:
        original = path.read_text(encoding="utf-8").splitlines(keepends=True)
    except Exception as e:  # pragma: no cover (unlikely)
        print(f"ERROR: cannot read {path}: {e}", file=sys.stderr)
        return False

    changed = False
    new_lines: list[str] = []
    for line in original:
        if line.strip() == "path:":
            new_line = line.replace("path:", "path: []")
            if verbose:
                print(f"NORMALIZE: {path}")
            new_lines.append(new_line)
            changed = True
        else:
            new_lines.append(line)

    if changed and apply:
        path.write_text("".join(new_lines), encoding="utf-8")
    return changed


def main() -> int:
    ap = argparse.ArgumentParser(description="Normalize empty path: to path: [] in metadata")
    ap.add_argument("--root", default="policies", help="Root directory to scan (default: policies)")
    ap.add_argument("--apply", action="store_true", help="Apply changes in-place (otherwise dry-run)")
    ap.add_argument("-v", "--verbose", action="store_true", help="Verbose per-file output")
    args = ap.parse_args()

    root = Path(args.root)
    if not root.exists():
        print(f"ERROR: root '{root}' does not exist", file=sys.stderr)
        return 1

    files = find_metadata_files(root)
    modified = 0
    candidates = 0
    for f in files:
        # quick pre-check: skip files without pattern to avoid reading all (micro-opt)
        try:
            text = f.read_text(encoding="utf-8")
        except Exception as e:  # pragma: no cover
            print(f"ERROR: cannot read {f}: {e}", file=sys.stderr)
            continue
        if "\npath:\n" not in f"\n{text}\n" and not text.endswith("path:\n"):
            continue
        candidates += 1
        # re-run through normalize logic for fidelity
        if normalize_file(f, apply=args.apply, verbose=args.verbose):
            modified += 1

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"[normalize-metadata-paths] Mode: {mode}; candidates: {candidates}; modified: {modified}")
    if not args.apply and modified:
        print("(dry-run) Re-run with --apply to write changes")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
