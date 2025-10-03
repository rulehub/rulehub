#!/usr/bin/env python3
"""Enforce that every policy directory containing policy.rego also has a policy_test.rego
and that metadata.yaml 'path' field (when array) includes both files.

Exit codes:
 0 - OK
 1 - Violations found
"""

from __future__ import annotations

from pathlib import Path

import yaml


POLICY_ROOT = Path("policies")


def norm_paths(p):
    if p is None:
        return []
    if isinstance(p, str):
        return [p]
    if isinstance(p, (list, tuple)):
        return [str(x) for x in p]
    return []


def main() -> int:
    violations: list[str] = []
    for meta in POLICY_ROOT.glob("**/metadata.yaml"):
        base_dir = meta.parent
        with open(meta, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        policy_file = base_dir / "policy.rego"
        test_file = base_dir / "policy_test.rego"
        has_policy = policy_file.exists()
        has_test = test_file.exists()
        if has_policy and not has_test:
            violations.append(f"Missing test file: {test_file} (policy exists)")
        if has_test and not has_policy:
            violations.append(f"Missing policy file: {policy_file} (test exists)")
        paths = norm_paths(data.get("path"))
        # Only enforce when both files actually exist
        if has_policy and has_test:
            for needed in (policy_file, test_file):
                if str(needed) not in paths:
                    violations.append(f"Metadata {meta} path missing entry for {needed}")
    if violations:
        print("Policy test pair enforcement FAILED:")
        for v in violations:
            print(f" - {v}")
        return 1
    print("Policy test pair enforcement OK")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
