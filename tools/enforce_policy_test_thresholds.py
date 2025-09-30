#!/usr/bin/env python3
"""Enforce policy test coverage quality thresholds in CI.

Reads dist/policy-test-coverage.json (produced by tools/policy_test_coverage.py)
and fails (exit code 2) if thresholds are not met.

Environment variables (all optional):
  REQUIRED_DUAL_PCT        Minimum percent of dual-direction policies (default: 100)
  ALLOW_MULTI_INADEQUATE   Maximum count of multi-rule inadequacies (default: 0)
  VERBOSE                  If set >0, print full JSON stats on success.

Exit codes:
  0 success (thresholds met)
  1 usage / missing file
  2 threshold failure
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


COVERAGE_JSON = Path("dist/policy-test-coverage.json")


def env_int(name: str, default: int) -> int:
    val = os.environ.get(name)
    if val is None or val == "":
        return default
    try:
        return int(val)
    except ValueError:
        print(
            f"[threshold] Invalid integer for {name}={val!r}", file=sys.stderr)
        sys.exit(1)


def main() -> int:
    if not COVERAGE_JSON.exists():
        print("[threshold] Coverage JSON missing. Run 'make policy-test-coverage' first.", file=sys.stderr)
        return 1
    data = json.loads(COVERAGE_JSON.read_text(encoding="utf-8"))
    required_dual_pct = env_int("REQUIRED_DUAL_PCT", 100)
    allow_multi_inadequate = env_int("ALLOW_MULTI_INADEQUATE", 0)
    dual_pct = data.get("dual_direction", {}).get("percent", 0)
    multi_inadequate = data.get("multi_rule", {}).get("count_inadequate", 0)
    # Historical dimension removed; always zero.
    failures: list[str] = []
    if dual_pct < required_dual_pct:
        failures.append(
            f"dual-direction percent {dual_pct}% < required {required_dual_pct}%"
        )
    if multi_inadequate > allow_multi_inadequate:
        failures.append(
            f"multi-rule inadequacies {multi_inadequate} > allowed {allow_multi_inadequate}"
        )
    if failures:
        print("[threshold] FAILURE: thresholds not met:")
        for f in failures:
            print(f"  - {f}")
        print(
            "[threshold] Adjust env vars REQUIRED_DUAL_PCT / ALLOW_MULTI_INADEQUATE / "
            "(deprecated policy allowance removed)"
        )
        return 2
    print(
        "[threshold] OK: dual={dual}% (min {req_dual}%) | multi_inadequate={multi} (allow {allow_multi})".format(
            dual=dual_pct,
            req_dual=required_dual_pct,
            multi=multi_inadequate,
            allow_multi=allow_multi_inadequate,
        )
    )
    if env_int("VERBOSE", 0) > 0:
        print(json.dumps(data, indent=2))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
