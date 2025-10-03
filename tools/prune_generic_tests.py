#!/usr/bin/env python3
"""Prune generic control-flag test cases for policies that have real evidence paths.

Logic:
  For each policy.rego gather evidence paths via regex (input.<path> == false).
  If evidence list non-empty, open corresponding policy_test.rego (skip curated) and remove:
    - test_denies_when_generic_control_flag_false block
    - test_denies_when_both_failure_conditions block
  Leave other tests intact.

Idempotent: running again makes no further changes.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent / 'policies'
EVIDENCE_RE = re.compile(r'input\.([a-zA-Z0-9_\.]+)\s*==\s*false')
GENERIC_TEST_NAMES = {
    'test_denies_when_generic_control_flag_false',
    'test_denies_when_both_failure_conditions',
}


def collect_evidences(policy_path: Path) -> set[str]:
    text = policy_path.read_text(encoding='utf-8')
    return {m.group(1) for m in EVIDENCE_RE.finditer(text)}


def prune_tests(test_path: Path) -> bool:
    text = test_path.read_text(encoding='utf-8')
    if '# curated' in text.splitlines()[:15]:
        return False
    lines = text.splitlines()
    out: list[str] = []
    skip = False
    removed_any = False
    for i, line in enumerate(lines):
        if not skip:
            # detect start of a block we want to skip
            for name in GENERIC_TEST_NAMES:
                if line.startswith(name + ' if {') or line.startswith(name + ' if{'):
                    skip = True
                    removed_any = True
                    break
            if skip:
                continue
            out.append(line)
        else:
            # inside skip until solitary closing brace '}' line encountered
            if line.strip() == '}':
                skip = False
            # do not append skipped lines
    if removed_any:
        # remove trailing extra blank lines
        cleaned = []
        prev_blank = False
        for line_out in out:
            if line_out.strip() == '':
                if prev_blank:
                    continue
                prev_blank = True
            else:
                prev_blank = False
            cleaned.append(line_out)
        test_path.write_text('\n'.join(cleaned) + '\n', encoding='utf-8')
    return removed_any


def main():
    pruned = 0
    for policy in ROOT.rglob('policy.rego'):
        evidences = collect_evidences(policy)
        if not evidences:
            continue
        test_file = policy.with_name('policy_test.rego')
        if not test_file.exists():
            continue
        if prune_tests(test_file):
            pruned += 1
    print(f'Pruned generic tests from: {pruned} files')


if __name__ == '__main__':
    main()
