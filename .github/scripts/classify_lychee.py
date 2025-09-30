#!/usr/bin/env python3
# ruff: noqa: I001
"""Classify lychee link check failures allowing soft transient codes.

Usage: classify_lychee.py lychee.json

Exit codes:
 0 - All good OR only soft failures (429, 500-599)
 1 - Hard failures present (non-soft HTTP codes)
 2 - Invalid input / parsing error
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


SOFT_STATUSES = {429} | set(range(500, 600))


def main(path: str) -> int:
    p = Path(path)
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:  # pragma: no cover - defensive
        print(
            f"[classify-lychee] Failed to read/parse JSON: {e}", file=sys.stderr)
        return 2

    errors = data.get("errors") or []
    if not errors:
        print(
            "[classify-lychee] No errors remaining (previous attempts likely transient)")
        return 0

    soft = []
    hard = []
    for err in errors:
        status = err.get("status")
        # status may be string (e.g. "Timeout") or int
        if isinstance(status, int) and status in SOFT_STATUSES:
            soft.append(err)
        else:
            hard.append(err)

    if hard:
        print("[classify-lychee] Hard link failures detected:")
        for h in hard:
            print(
                f"  {h.get('status')} {h.get('link')} (source: {h.get('source')} line {h.get('line')})")
        if soft:
            print(
                "[classify-lychee] Soft/transient failures (ignored for success criteria):")
            for s in soft:
                print(
                    f"  {s.get('status')} {s.get('link')} (source: {s.get('source')} line {s.get('line')})")
        return 1

    # Only soft failures
    print("[classify-lychee] Only soft/transient link failures (treated as success):")
    for s in soft:
        print(
            f"  {s.get('status')} {s.get('link')} (source: {s.get('source')} line {s.get('line')})")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: classify_lychee.py lychee.json", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
