#!/usr/bin/env python3
"""Strict aggregate test enforcement.

Fail (exit code 2) if any policy with >1 deny rule lacks an aggregate
test named:

  test_<policy_id>_denies_when_any_violation

Where <policy_id> is the package suffix after `package rulehub.` with dots
converted to underscores (e.g. rulehub.k8s.no_privileged -> k8s_no_privileged).

The aggregate test body must assert at least one finding via either
`count(deny) > 0`, `count(deny) >= 1`, `deny[` or `some _ in deny`.

Heuristics only — fast regex scan (no OPA parse). Intended to be run via
`make test-strict` in CI / pre-commit for hard gating once repository
has adopted the pattern. Policies with a single deny rule are ignored.

Environment (optional):
  VERBOSE=1  -> emit per-policy debug info
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path


POLICIES_ROOT = Path("policies")

RE_DENY_RULE = re.compile(r'^\s*deny\b')
RE_PACKAGE = re.compile(r'^\s*package\s+rulehub\.(?P<id>[a-zA-Z0-9_.]+)\s*$')
RE_AGG_ASSERT = re.compile(r'(count\(\s*deny\s*\)\s*>\s*0)|(count\(\s*deny\s*\)\s*>=\s*1)|deny\[|some\s+_?\s+in\s+deny')


def discover_policy_id(policy_path: Path) -> str | None:
    for line in policy_path.read_text(encoding='utf-8').splitlines():
        m = RE_PACKAGE.match(line)
        if m:
            return m.group('id')
    return None


def count_deny_rules(policy_path: Path) -> int:
    return sum(1 for line in policy_path.read_text(encoding='utf-8').splitlines() if RE_DENY_RULE.search(line))


def aggregate_test_present(policy_id: str, test_file: Path) -> bool:
    """Return True if aggregate test function exists with required assertion."""
    if not test_file.exists():
        return False
    pid_underscored = policy_id.replace('.', '_')
    expected_name = f"test_{pid_underscored}_denies_when_any_violation"
    text = test_file.read_text(encoding='utf-8')
    # Search for test block start `expected_name if {` (allow trailing spaces)
    # and ensure within its block there is an aggregate assertion.
    # Simplify: if function name present anywhere AND any aggregate assertion present in file.
    if expected_name in text and RE_AGG_ASSERT.search(text):
        return True
    return False


def main() -> int:
    verbose = os.environ.get('VERBOSE', '0') not in ('', '0')
    policy_files = sorted(POLICIES_ROOT.glob('**/policy.rego'))
    if not policy_files:
        print('[strict-tests] No policy.rego files found', file=sys.stderr)
        return 1
    missing: list[tuple[str, str]] = []  # (policy_id, path_dir)
    for policy in policy_files:
        policy_id = discover_policy_id(policy)
        if not policy_id:
            if verbose:
                print(f"[strict-tests] Skipping (no package id): {policy}")
            continue
        deny_count = count_deny_rules(policy)
        if deny_count <= 1:
            if verbose:
                print(f"[strict-tests] OK (single deny rule -> no aggregate required): {policy_id}")
            continue
        test_file = policy.parent / 'policy_test.rego'
        if aggregate_test_present(policy_id, test_file):
            if verbose:
                print(f"[strict-tests] OK aggregate present: {policy_id}")
            continue
        missing.append((policy_id, str(test_file)))
        if verbose:
            print(f"[strict-tests] MISSING aggregate test: {policy_id} (expected in {test_file})")
    if missing:
        print('[strict-tests] FAILURE: missing aggregate any_violation tests for multi-deny policies:')
        for pid, tf in missing:
            print(f"  - {pid} (expected test_{pid.replace('.', '_')}_denies_when_any_violation in {tf})")
        print('[strict-tests] Add an aggregate test asserting >=1 finding (count(deny) > 0).')
        return 2
    print('[strict-tests] OK: all multi-deny policies have aggregate any_violation test')
    return 0


if __name__ == '__main__':  # pragma: no cover
    raise SystemExit(main())
