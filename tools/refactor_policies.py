#!/usr/bin/env python3
"""Refactor Rego policies to explicit evidence pattern and regenerate tests.

Actions per policy:
 1. Replace occurrences of 'not input.<path>' inside deny blocks with '<path> == false'.
 2. Collect each unique evidence path (<path> part after input.). Skips control flag paths.
 3. If the companion policy_test.rego appears to be in an outdated form (heuristics) regenerate
    a standard 4+N test suite:
        - test_allow_when_compliant
        - test_denies_when_<evidence>_false (one per evidence path)
        - test_denies_when_generic_control_flag_false
        - test_denies_when_both_failure_conditions

Heuristics for outdated test file:
  - Contains 'Auto-generated granular test' OR 'test_violation_when_noncompliant'
  - OR missing 'test_denies_when_both_failure_conditions'

Usage:
  Dry run (default):    python tools/refactor_policies.py
  Apply changes:        python tools/refactor_policies.py --apply

Limitations:
  - Simple regex; assumes no multiline 'not input.' expressions spanning lines.
  - Leaves already refactored policies untouched.
  - Does not modify metadata.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent / "policies"
NOT_INPUT_RE = re.compile(r"not (input[.][A-Za-z0-9_\.]+(?:\.[A-Za-z0-9_]+)*)")


def replace_not_input(line: str, evidence_paths: set[str]) -> str:
    def _sub(m: re.Match) -> str:
        full = m.group(1)  # e.g. input.part11.validation_evidence_available
        path = full[len("input."):]
        evidence_paths.add(path)
        return f"{full} == false"

    # Only operate inside deny rule lines or generic lines; safe global line transform
    if "not input." in line:
        return NOT_INPUT_RE.sub(_sub, line)
    return line


def build_nested(path: str, value) -> dict:
    parts = path.split(".")
    d = value
    for part in reversed(parts):
        d = {part: d}
    return d


def merge_dict(a: dict, b: dict) -> dict:
    for k, v in b.items():
        if k in a and isinstance(a[k], dict) and isinstance(v, dict):
            merge_dict(a[k], v)
        else:
            a.setdefault(k, v)
    return a


def generate_tests(package: str, policy_id: str, evidence_paths: list[str]) -> str:
    # Assemble base inputs
    evidence_true = {}
    for p in evidence_paths:
        merge_dict(evidence_true, build_nested(p, True))
    evidence_false = {}
    for p in evidence_paths:
        merge_dict(evidence_false, build_nested(p, False))

    def obj(**kwargs):
        return json.dumps(kwargs, separators=(",", ":"))

    lines = [f"package {package}", ""]
    # Happy path
    happy_input = {"controls": {policy_id: True}, **evidence_true}
    lines.append("test_allow_when_compliant if {")
    lines.append(f"    allow with input as {obj(**happy_input)}")
    lines.append("}")
    lines.append("")
    # Per-evidence deny tests
    for p in evidence_paths:
        single_false = {"controls": {policy_id: True}, **evidence_true}
        # override that one evidence path to false
        merge_dict(single_false, build_nested(p, False))
        test_name = f"test_denies_when_{p.replace('.', '_')}_false"
        lines.append(f"{test_name} if {{")
        lines.append(f"    some _ in deny with input as {obj(**single_false)}")
        lines.append("}")
        lines.append("")
    # Generic control flag false
    generic_false_input = {"controls": {policy_id: False}, **evidence_true}
    lines.append("test_denies_when_generic_control_flag_false if {")
    lines.append(
        f"    some _ in deny with input as {obj(**generic_false_input)}")
    lines.append("}")
    lines.append("")
    # Both failure conditions
    both_fail_input = {"controls": {policy_id: False}, **evidence_false}
    lines.append("test_denies_when_both_failure_conditions if {")
    lines.append(f"    some _ in deny with input as {obj(**both_fail_input)}")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def needs_regen(test_text: str) -> bool:
    if "test_denies_when_both_failure_conditions" not in test_text:
        return True
    if "Auto-generated granular test" in test_text:
        return True
    if "test_violation_when_noncompliant" in test_text:
        return True
    return False


def main(apply: bool = False):
    modified = []
    regenerated = []
    for policy_file in ROOT.rglob("policy.rego"):
        policy_text = policy_file.read_text(encoding="utf-8")
        evidence_paths: set[str] = set()
        new_lines = []
        changed = False
        for line in policy_text.splitlines():
            new_line = replace_not_input(line, evidence_paths)
            if new_line != line:
                changed = True
            new_lines.append(new_line)
        if not changed:
            continue  # skip already refactored
        # rewrite policy file
        if apply:
            policy_file.write_text(
                "\n".join(new_lines) + "\n", encoding="utf-8")
        modified.append(policy_file)

        # Determine package & policy id for tests
        m = re.search(r"package\s+([a-z0-9_.]+)", policy_text)
        if not m:
            continue
        package = m.group(1)
        # policy id is package without leading 'rulehub.'
        policy_id = package.split(".", 1)[1] if package.startswith(
            "rulehub.") else package
        test_file = policy_file.with_name("policy_test.rego")
        if not test_file.exists():
            continue
        test_text = test_file.read_text(encoding="utf-8")
        if not needs_regen(test_text):
            continue
        if not evidence_paths:
            continue  # nothing to build tests from
        new_test = generate_tests(package, policy_id, sorted(evidence_paths))
        if apply:
            test_file.write_text(new_test, encoding="utf-8")
        regenerated.append(test_file)

    print(f"Policies modified: {len(modified)}")
    print(f"Tests regenerated: {len(regenerated)}")
    if not apply:
        print("(dry-run) pass --apply to write changes")
    else:
        for f in modified:
            print("MOD:", f)
        for f in regenerated:
            print("REGEN:", f)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true",
                    help="Write changes to disk")
    args = ap.parse_args()
    main(apply=args.apply)
