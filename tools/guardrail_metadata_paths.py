#!/usr/bin/env python3
"""Guardrail: enforce explicit placeholder semantics for metadata `path` fields.

Accepted forms (NORMAL mode):
    - `path: []`            (placeholder – advisory only, encourages later replacement)
    - `path: <value/list>`  (populated list or scalar path(s))

Failure conditions:
        - A line exactly matching `^path:\\s*$` (bare key with no value or list) in all modes.
    - When environment variable `STRICT_EMPTY_PATHS=1` is set: any occurrence of `path: []`.

Exit codes:
    0  No violations
    2  Violations found (either bare path or disallowed placeholder in STRICT mode)
    1  Unexpected internal error

Integration notes:
    - Invoked by `make guardrail-metadata-paths` and included in `make guardrails`.
    - To enable strict placeholder banning in CI, run: `STRICT_EMPTY_PATHS=1 make guardrails`.

Examples:
    $ python tools/guardrail_metadata_paths.py
    $ STRICT_EMPTY_PATHS=1 python tools/guardrail_metadata_paths.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path


def scan(root: Path, strict: bool) -> list[str]:
    violations: list[str] = []
    for meta in sorted(root.rglob("metadata.yaml")):
        try:
            lines = meta.read_text(encoding="utf-8").splitlines()
        except Exception as e:  # pragma: no cover
            print(f"ERROR: cannot read {meta}: {e}", file=sys.stderr)
            continue
        for i, line in enumerate(lines, start=1):
            stripped = line.strip()
            if stripped == "path:":
                # Look ahead to see if a properly indented YAML list follows
                j = i  # 1-based index; lines list is 0-based
                has_items = False
                while j < len(lines):
                    nxt = lines[j].rstrip("\n")
                    if not nxt.strip():
                        break  # blank -> stop search
                    if nxt.lstrip().startswith('#'):
                        j += 1
                        continue  # skip comments
                    # Next top-level key (heuristic): starts without leading space and contains ':'
                    if not nxt.startswith(' ') and ':' in nxt.split()[0]:
                        break
                    if nxt.lstrip().startswith('- '):
                        has_items = True
                        break
                    # If indented but not list item, skip (could be multiline scalar)
                    if not nxt.startswith(' '):
                        break
                    j += 1
                if not has_items:
                    violations.append(f"{meta}:{i}: empty path value (should be [] or populated list)")
            elif strict and stripped == "path: []":
                violations.append(f"{meta}:{i}: empty path placeholder not allowed in STRICT mode")
    return violations


def main() -> int:
    root = Path("policies")
    if not root.exists():
        print("ERROR: policies directory not found", file=sys.stderr)
        return 1
    strict = os.environ.get("STRICT_EMPTY_PATHS") == "1"
    violations = scan(root, strict=strict)
    if violations:
        header = (
            "[guardrail-metadata-paths] Violations (STRICT mode)" if strict else "[guardrail-metadata-paths] Violations"
        )
        print(header)
        for v in violations:
            print("  - ", v, sep="")
        print(f"Total: {len(violations)} violation(s)")
        return 2
    mode = "STRICT" if strict else "NORMAL"
    print(f"[guardrail-metadata-paths] OK (mode={mode})")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
