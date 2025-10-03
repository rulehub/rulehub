#!/usr/bin/env python3
"""Fail if any policy_test.rego relies ONLY on a generic control toggle to trigger a deny.

Heuristic:
* A "generic-only" deny test sets the policy control false under `controls` and supplies
    no additional top-level evidence objects.
* Tests with extra evidence objects (player, limits, transaction, etc.) are fine even if
    they also exercise the control=false path.
* Failure condition: all deny assertions for a policy are generic-only AND the policy
    references evidence fields (naive scan for "input.<segment>." beyond controls).

Output:
* Lists offending policies and their generic-only test rule names; exit 2 if any.

Limitations:
* Heuristic (regex) – acceptable guardrail; can be upgraded to AST parsing later.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


def _accumulate_multiline_json(lines: list[str], start_index: int, first_line_start: int) -> dict | None:
    """Accumulate lines starting at start_index to build a balanced JSON object.

    first_line_start is the position of the first '{' in lines[start_index].
    Returns parsed dict or None.
    """
    snippet_parts: list[str] = []
    depth = 0
    started = False
    for i in range(start_index, len(lines)):
        seg = lines[i]
        if i == start_index:
            seg_iter = seg[first_line_start:]
        else:
            seg_iter = seg
        snippet_parts.append(seg_iter)
        for ch in seg_iter:
            if ch == '{':
                depth += 1
                started = True
            elif ch == '}':
                depth -= 1
                if started and depth == 0:
                    # Attempt parse
                    candidate = '\n'.join(snippet_parts)
                    return extract_json_like(candidate)
        # continue until depth returns to zero
    return None


POLICIES_ROOT = Path("policies")
GENERIC_CONTROL_PATTERN = re.compile(r'"controls"\s*:\s*\{[^}]*?"[\w.]+":\s*false', re.IGNORECASE)
INPUT_PREFIX_RE = re.compile(r'with\s+input\s+as\s+\{')  # start of inline JSON
RULE_HEAD_PATTERN = re.compile(r'^\s*test_[\w]+')
# Evidence hint: presence of input.<alpha>.<alpha> beyond input.controls
EVIDENCE_REF_PATTERN = re.compile(r'input\.(?!controls)[a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*)+')

# Deny assertion lines patterns borrowed from coverage tool
DENY_ASSERT_RE = re.compile(r'(?:count\(\s*deny\s*\)\s*>\s*0)|(?:deny\[)')


def extract_json_like(obj_str: str) -> dict | None:
    """Attempt JSON parse; return dict or None.

    Heuristic fallbacks:
    - Remove trailing commas before closing braces/brackets to tolerate
      common Rego test object formatting.
    """
    try:
        return json.loads(obj_str)
    except Exception:
        pass
    # Fallback: strip trailing commas before } or ] on any line
    try:
        cleaned = re.sub(r",\s*([}\]])", r"\1", obj_str)
        return json.loads(cleaned)
    except Exception:
        return None


def extract_balanced_input_object(line: str) -> dict | None:
    """Extract a balanced JSON object after 'with input as'.

    Tests serialize entire input on one line. We balance braces to avoid premature
    termination (nested objects).
    """
    m = INPUT_PREFIX_RE.search(line)
    if not m:
        return None
    brace_start = line.find('{', m.end() - 1)
    if brace_start == -1:
        return None
    depth = 0
    for i, ch in enumerate(line[brace_start:], start=brace_start):
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                snippet = line[brace_start : i + 1]
                return extract_json_like(snippet)
    return None


def policy_has_evidence_checks(policy_text: str) -> bool:
    # If deny rule references input.<something> besides controls, we treat as evidence-based
    return bool(EVIDENCE_REF_PATTERN.search(policy_text))


def main() -> int:
    offenders: list[dict] = []
    for pol in POLICIES_ROOT.glob("**/policy.rego"):
        policy_text = pol.read_text(encoding="utf-8")
        policy_dir = pol.parent
        test_file = policy_dir / "policy_test.rego"
        if not test_file.exists():
            continue
        if not policy_has_evidence_checks(policy_text):
            # Nothing to enforce; policy only uses controls or simple flags
            continue
        ttext = test_file.read_text(encoding="utf-8")
        lines = ttext.splitlines()
        current_rule = None
        generic_only_rules: list[str] = []
        deny_rules_total = 0
        rule_has_non_generic_input = False
        rule_has_deny_assert = False
        # per_rule_generic tracking not needed currently (could store future metadata)
        for idx, line in enumerate(lines):
            m_head = RULE_HEAD_PATTERN.match(line)
            if m_head:
                # finalize previous rule
                if current_rule is not None:
                    if rule_has_deny_assert and not rule_has_non_generic_input:
                        generic_only_rules.append(current_rule)
                    if rule_has_deny_assert:
                        deny_rules_total += 1
                current_rule = line.strip().split()[0]
                rule_has_non_generic_input = False
                rule_has_deny_assert = False
                continue
            if 'with input as' in line:
                obj = extract_balanced_input_object(line)
                if obj is None:
                    # Multi-line object scenario
                    brace_pos = line.find('{')
                    if brace_pos != -1:
                        obj = _accumulate_multiline_json(lines, idx, brace_pos)
                if isinstance(obj, dict):
                    keys = set(obj.keys())
                    non_control_keys = [k for k in keys if k != 'controls']
                    if non_control_keys:
                        rule_has_non_generic_input = True
            if DENY_ASSERT_RE.search(line):
                rule_has_deny_assert = True
        # finalize last rule (still inside policy loop)
        if current_rule is not None:
            if rule_has_deny_assert and not rule_has_non_generic_input:
                generic_only_rules.append(current_rule)
            if rule_has_deny_assert:
                deny_rules_total += 1
        # Only flag if every deny rule for the policy is generic-only
        if deny_rules_total > 0 and len(generic_only_rules) == deny_rules_total:
            offenders.append(
                {
                    "policy": str(pol),
                    "test": str(test_file),
                    "generic_only_rules": generic_only_rules,
                }
            )
    if offenders:
        print("[generic-only] Found policies whose deny tests rely only on generic control toggles:")
        for off in offenders:
            print(f" - {off['policy']} -> {', '.join(off['generic_only_rules'])}")
        print("Add at least one deny test with evidence fields beyond controls{}.".format(" for each listed policy"))
        return 2
    print("[generic-only] OK: no generic-control-only deny test sets detected")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
