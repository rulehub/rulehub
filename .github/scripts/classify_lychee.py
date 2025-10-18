#!/usr/bin/env python3
# ruff: noqa: I001
"""Classify lychee link check failures allowing soft transient codes.

Usage: classify_lychee.py lychee.json

Exit codes:
 0 - All good OR only soft failures (429, 500-599)
 1 - Hard failures present (non-soft HTTP codes)
 2 - Invalid input / parsing error
"""
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, cast


SOFT_STATUSES = {429} | set(range(500, 600))


def _normalize_error(src: Optional[str], err: Dict[str, Any]) -> Dict[str, Any]:
    """Return a normalized error dict with keys: status (any), link (str), source (str), line (int|None)."""
    status = err.get("status") or err.get("code") or err.get("status_code") or err.get("statusCode")
    link = err.get("link") or err.get("uri") or err.get("url") or err.get("target")
    line = err.get("line") or err.get("line_no") or err.get("lineNumber")
    return {
        "status": status,
        "link": link,
        "source": err.get("source") or err.get("file") or src,
        "line": line,
    }


def _extract_errors(data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Best-effort extraction of error entries from lychee JSON across versions.

    Supports both:
    - legacy schema with top-level "errors" array of entries
    - newer schema where "errors" is a count and details live under "fail_map" (per-source arrays)
      or a flat "failures" array.
    """
    raw_any = data.get("errors")
    if isinstance(raw_any, list):
        # Already an array of error entries
        raw_list: List[Any] = cast(List[Any], raw_any)
        out: List[Dict[str, Any]] = []
        for item in raw_list:
            if isinstance(item, dict):
                item_dict: Dict[str, Any] = cast(Dict[str, Any], item)
                src_val_any = item_dict.get("source")
                src_val: Optional[str] = src_val_any if isinstance(src_val_any, str) else None
                out.append(_normalize_error(src_val, item_dict))
        return out

    # Try fail_map: { source: [ {status, link, ...}, ...], ... }
    fm_any = data.get("fail_map")
    if isinstance(fm_any, dict):
        out2: List[Dict[str, Any]] = []
        fm_dict: Dict[str, Any] = cast(Dict[str, Any], fm_any)
        for src_key, arr_any in fm_dict.items():
            if isinstance(arr_any, list):
                arr_list: List[Any] = cast(List[Any], arr_any)
                for item in arr_list:
                    if isinstance(item, dict):
                        item_dict: Dict[str, Any] = cast(Dict[str, Any], item)
                        out2.append(_normalize_error(str(src_key), item_dict))
        return out2

    # Try failures: [ {status, link, source?, ...}, ... ]
    failures_any = data.get("failures")
    if isinstance(failures_any, list):
        out3: List[Dict[str, Any]] = []
        fl_list: List[Any] = cast(List[Any], failures_any)
        for item in fl_list:
            if isinstance(item, dict):
                item_dict2: Dict[str, Any] = cast(Dict[str, Any], item)
                src_val_any2 = item_dict2.get("source")
                src_val2: Optional[str] = src_val_any2 if isinstance(src_val_any2, str) else None
                out3.append(_normalize_error(src_val2, item_dict2))
        return out3

    # Last resort: empty list; caller will fall back to count-only logic
    return []


def main(path: str) -> int:
    p = Path(path)
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:  # pragma: no cover - defensive
        print(
            f"[classify-lychee] Failed to read/parse JSON: {e}", file=sys.stderr)
        return 2

    entries: List[Dict[str, Any]] = _extract_errors(cast(Dict[str, Any], data))
    # If no entries extracted, fall back to count semantics if available
    if not entries:
        count = data.get("errors")
        try:
            count_int = int(count)
        except Exception:
            count_int = 0
        if count_int <= 0:
            print("[classify-lychee] No errors remaining (previous attempts likely transient)")
            return 0
        # Without per-entry details, we can't separate soft vs hard reliably.
        # Be conservative and treat as hard failures.
        print(f"[classify-lychee] {count_int} errors reported but details not found; treating as hard failures.")
        return 1

    soft: List[Dict[str, Any]] = []
    hard: List[Dict[str, Any]] = []
    for err in entries:
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
