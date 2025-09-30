#!/usr/bin/env python3
"""Repair corrupted policy_test.rego files to standard evidence-based pattern.

Heuristics to rewrite a test file:
  - Contains patterns '"controls":true' or '"controls":false' (missing object)
  - OR missing 'test_allow_when_compliant'
    - OR contains outdated 'test_denies_when_controls_false'

Evidence paths are extracted from policy.rego deny rules by regex:
    input.<path> == false
Constant context constraints (e.g., input.region == "AU") are also captured and injected into all test inputs.

Generated tests:
  test_allow_when_compliant
  test_denies_when_<evidence>_false (per evidence path)
  test_denies_when_generic_control_flag_false
  test_denies_when_both_failure_conditions

If no evidence paths found (only control flag), only generic flag tests are produced.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent / 'policies'
POLICY_GLOB = '**/policy.rego'
EVIDENCE_RE = re.compile(r'input\.([a-zA-Z0-9_\.]+)\s*==\s*false')
CONST_RE = re.compile(r'input\.([a-zA-Z0-9_\.]+)\s*==\s*"([^"]+)"')
PACKAGE_RE = re.compile(r'^package\s+([a-z0-9_.]+)', re.MULTILINE)
ALLOW_RE = re.compile(r'^[ \t]*allow(?:\s*(?:if|:=))', re.MULTILINE)

REWRITE_TRIGGER_PATTERNS = [
    '"controls":true',
    '"controls":false',
    'test_denies_when_controls_false',
    '_failing if {',
    'some _ in deny',
    'not deny[_]'
]


def build_nested(path: str, value):
    parts = path.split('.')
    d = value
    for part in reversed(parts):
        d = {part: d}
    return d


def deep_merge(a: dict, b: dict):
    for k, v in b.items():
        if k in a and isinstance(a[k], dict) and isinstance(v, dict):
            deep_merge(a[k], v)
        else:
            a.setdefault(k, v)
    return a


def collect_policy_info(policy_path: Path):
    text = policy_path.read_text(encoding='utf-8')
    pkg_m = PACKAGE_RE.search(text)
    if not pkg_m:
        return None
    package = pkg_m.group(1)
    policy_id = package.split('.', 1)[1] if package.startswith(
        'rulehub.') else package
    evidences = set(m.group(1) for m in EVIDENCE_RE.finditer(text))
    consts = [(m.group(1), m.group(2)) for m in CONST_RE.finditer(text)]
    has_allow = bool(ALLOW_RE.search(text))
    return {
        'package': package,
        'policy_id': policy_id,
        'evidences': sorted(evidences),
        'consts': consts,
        'text': text,
        'has_allow': has_allow,
    }


def needs_rewrite(test_text: str) -> bool:
    if 'test_allow_when_compliant' not in test_text:
        return True
    for pat in REWRITE_TRIGGER_PATTERNS:
        if pat in test_text:
            return True
    return False


def compose_input(
    policy_id: str,
    controls_value: bool,
    evidences: list[str],
    false_subset: set[str],
    consts: list[tuple[str, str]],
) -> dict[str, Any]:
    """Build an input document.

    controls_value sets the control flag for the policy id.
    evidences lists boolean evidence paths; those in false_subset are set to false, others true.
    consts provides (path, value) string constants always included.
    """
    base: dict[str, Any] = {'controls': {policy_id: controls_value}}
    # evidence values
    for ev in evidences:
        val = False if ev in false_subset else True
        deep_merge(base, build_nested(ev, val))  # type: ignore[arg-type]
    # constants
    for path, value in consts:
        deep_merge(base, build_nested(path, value))  # type: ignore[arg-type]
    return base


def generate_tests(info):
    package = info['package']
    policy_id = info['policy_id']
    evidences = info['evidences']
    consts = info['consts']
    has_allow = info.get('has_allow', False)
    lines = [f'package {package}', '']
    # allow
    allow_input = compose_input(policy_id, True, evidences, set(), consts)
    lines.append('test_allow_when_compliant if {')
    if has_allow:
        lines.append(
            f'    allow with input as {json.dumps(allow_input, separators=(",", ":"))}')
    else:
        lines.append(
            f'    count(deny) == 0 with input as {json.dumps(allow_input, separators=(",", ":"))}')
    lines.append('}')
    lines.append('')
    # per evidence denies
    for ev in evidences:
        deny_input = compose_input(policy_id, True, evidences, {ev}, consts)
        lines.append(f'test_denies_when_{ev.replace(".", "_")}_false if {{')
        lines.append(
            f'    count(deny) > 0 with input as {json.dumps(deny_input, separators=(",", ":"))}')
        lines.append('}')
        lines.append('')
    # generic control flag: include only one control-based deny if no evidences, else still keep control variant
    generic_input = compose_input(policy_id, False, evidences, set(), consts)
    if not evidences:
        lines.append('test_denies_when_generic_control_flag_false if {')
        lines.append(
            f'    count(deny) > 0 with input as {json.dumps(generic_input, separators=(",", ":"))}')
        lines.append('}')
        lines.append('')
    else:
        lines.append('test_denies_when_generic_control_flag_false if {')
        lines.append(
            f'    count(deny) > 0 with input as {json.dumps(generic_input, separators=(",", ":"))}')
        lines.append('}')
        lines.append('')
        # both failure conditions only meaningful when evidences exist
        both_input = compose_input(
            policy_id, False, evidences, set(evidences), consts)
        lines.append('test_denies_when_both_failure_conditions if {')
        lines.append(
            f'    count(deny) > 0 with input as {json.dumps(both_input, separators=(",", ":"))}')
        lines.append('}')
        lines.append('')
    return '\n'.join(lines)


def file_is_curated(text: str) -> bool:
    return '# curated' in text.splitlines()[:15]


def main():
    rewritten = 0
    for policy in ROOT.rglob('policy.rego'):
        info = collect_policy_info(policy)
        if not info:
            continue
        test_file = policy.with_name('policy_test.rego')
        if not test_file.exists():
            continue
        test_text = test_file.read_text(encoding='utf-8')
        if file_is_curated(test_text):
            continue
        # Trigger rewrites either by corruption patterns OR unsafe use of allow without rule
        if not needs_rewrite(test_text):
            if not info['has_allow'] and 'allow with input as' in test_text:
                pass  # force rewrite
            else:
                continue
        new_test = generate_tests(info)
        test_file.write_text(new_test, encoding='utf-8')
        rewritten += 1
    print(f'Rewritten test files: {rewritten}')


if __name__ == '__main__':
    main()
