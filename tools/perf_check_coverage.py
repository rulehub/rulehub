#!/usr/bin/env python3
"""Performance check for coverage_map.py generation.

Runs ``tools/coverage_map.py --profile`` capturing stage timings, parses the
output, and enforces a configurable total time threshold suitable for CI.

Environment variables:
  COVERAGE_MAX_SECONDS   Float threshold for total generation time (default 5.0)
  COVERAGE_WARN_SECONDS  Soft warning threshold (default = 0.75 * max)

Exit codes:
  0 success (within threshold)
  3 soft warning (exceeded warn threshold but below hard max)
  5 hard failure (exceeded hard max threshold)

Rationale / Projection (documented here so CI logs retain context):
  Baseline (current repository, measured via coverage_map.py --profile):
    load_metadata_index ~0.456 s for 283 policies (~1.61 ms/policy)
    total generation     ~0.594 s

  Scaling ×5 policies (~1415 policies) assuming linear cost for metadata load
  and negligible growth for map/misc stages:
      projected metadata stage ≈ 0.456 * 5 ≈ 2.28 s
      projected total          ≈ 0.594 - 0.456 + 2.28 ≈ 2.42 s
  Adding 25% buffer for CI variance: ≈ 3.0 s target ceiling today.

  We provision a conservative default hard threshold of 5.0 s to allow future
  moderate growth and transient runner noise; the soft warning (3.75 s) should
  prompt investigation before breaching the hard limit. Revisit thresholds if
  policy count or implementation changes materially.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from typing import Dict, Tuple


PROFILE_RE = re.compile(r"^\s{2}([a-z_]+)\s+([0-9]+\.[0-9]{4})$")


def run_profile() -> Tuple[Dict[str, float], str]:
    """Run coverage_map.py with profiling, returning timings dict and raw stdout."""
    proc = subprocess.run(
        [sys.executable, "tools/coverage_map.py", "--profile"],
        text=True,
        capture_output=True,
        check=False,
    )
    out = proc.stdout + ("\n" + proc.stderr if proc.stderr else "")
    timings: Dict[str, float] = {}
    for line in out.splitlines():
        m = PROFILE_RE.match(line)
        if m:
            name, dur = m.group(1), float(m.group(2))
            timings[name] = dur
    return timings, out


def main() -> int:
    max_seconds = float(os.environ.get("COVERAGE_MAX_SECONDS", "5.0"))
    warn_seconds = float(os.environ.get("COVERAGE_WARN_SECONDS", f"{max_seconds * 0.75}"))
    timings, raw = run_profile()
    total = timings.get("total") or sum(v for k, v in timings.items() if k != "total")
    status = "OK"
    exit_code = 0
    if total > max_seconds:
        status = "FAIL"
        exit_code = 5
    elif total > warn_seconds:
        status = "WARN"
        exit_code = 3
    # Structured single-line summary for easy grep in CI logs
    print(
        f"[perf-coverage] status={status} total={total:.4f}s max={max_seconds:.2f}s warn={warn_seconds:.2f}s stages="
        + ",".join(f"{k}:{v:.4f}" for k, v in sorted(timings.items()))
    )
    # Echo raw profile if warning/failure for debugging context
    if exit_code != 0:
        print("---- raw profile output ----")
        print(raw.strip())
    return exit_code


if __name__ == "__main__":  # pragma: no cover - simple CLI wrapper
    raise SystemExit(main())
