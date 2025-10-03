#!/usr/bin/env python3
"""Generate granular deny tests for multi-rule policies.

For each policy with >1 deny rule (heuristic: lines starting with 'deny contains msg if {'),
ensure the corresponding test file has one deny assertion per rule plus a generic control test.

Strategy:
1. Parse policy.rego, collect rule conditions inside each deny block up to closing '}'.
2. Extract a simple discriminating flag expression: prefer patterns:
   - input.<path> == false
   - input.<path> == true  (invert to false for failing case)
   - not input.<path>
3. Build failing input object where only that flag is set to failing value; others set to passing (true) when obvious.
4. Skip generating if a test referencing the unique flag path already exists.
5. Always preserve existing tests; append new ones at end with consistent naming.

Limitations: heuristic, doesn't execute Rego. Safe to re-run (idempotent) because it
checks for existing flag substrings.

Usage:
  Dry run (default): lists planned additions.
  --apply : writes changes.
  --limit N : only process first N policies.

"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Dict, List


POLICIES_ROOT = Path("policies")
TEST_FILENAME = "policy_test.rego"

DENY_RULE_START = re.compile(r"^\s*deny\s+contains\s+msg\s+if\s*{\s*$")
INPUT_FLAG_RE = re.compile(r"input\.([a-zA-Z0-9_\.\[\]\"]+)\s*(==\s*(true|false))?")
NOT_INPUT_RE = re.compile(r"not\s+input\.([a-zA-Z0-9_\.\[\]\"]+)")
# Match control key like input.controls[\"policy.id\"]
CONTROL_KEY_RE = re.compile(r"input\.controls\[\"([^\"]+)\"\]")


def extract_rule_blocks(text: str) -> List[List[str]]:
    lines = text.splitlines()
    blocks: List[List[str]] = []
    current: List[str] = []
    in_block = False
    brace_depth = 0
    for line in lines:
        if not in_block and DENY_RULE_START.match(line):
            in_block = True
            current = []
            brace_depth = 0
            continue
        if in_block:
            # Track braces to find block end
            brace_depth += line.count("{")
            brace_depth -= line.count("}")
            if brace_depth < 0 or line.strip() == "}":
                # End of block
                in_block = False
                blocks.append(current)
                continue
            current.append(line)
    return blocks


def derive_flag_from_block(block_lines: List[str]) -> str | None:
    joined = " \n".join(block_lines)
    # Prefer explicit equality checks
    m = INPUT_FLAG_RE.search(joined)
    if m:
        raw = m.group(1)
        # normalize control key access input.controls["id"] -> controls.id
        cm = CONTROL_KEY_RE.search(joined)
        if cm:
            return f"controls.{cm.group(1)}"
        return raw
    n = NOT_INPUT_RE.search(joined)
    if n:
        return n.group(1)
    # look for control key reference
    c = CONTROL_KEY_RE.search(joined)
    if c:
        return f"controls.{c.group(1)}"
    return None


def _assign(obj: Dict[str, Any], path: List[str], value: Any) -> None:
    cur: Dict[str, Any] = obj
    for i, seg in enumerate(path):
        last = i == len(path) - 1
        if last:
            cur[seg] = value
        else:
            cur = cur.setdefault(seg, {})  # type: ignore[assignment]


def build_failing_input(flags: List[str], target: str) -> Dict:
    """Create nested input structure with target flag set to False and others True.

    Heuristic: control keys (controls.<key>) grouped under controls; other dotted
    paths create nested objects. Keeps existing keys minimal for readability.
    """
    root: Dict[str, Any] = {"controls": {}}
    for f in flags:
        is_target = f == target
        value: Any = False if is_target else True
        segs = f.split('.')
        if segs[0] == 'controls':
            # controls.foo or deeper
            remainder = segs[1:]
            if not remainder:
                continue
            _assign(root.setdefault('controls', {}), remainder, value)
        else:
            _assign(root, segs, value)
    return root


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true', help='Write changes to test files')
    ap.add_argument('--limit', type=int, default=None)
    args = ap.parse_args()

    policy_files = list(POLICIES_ROOT.glob('**/policy.rego'))
    multi_policies = []
    for pol in policy_files:
        text = pol.read_text(encoding='utf-8')
        deny_count = len(re.findall(r'^\s*deny\b', text, flags=re.MULTILINE))
        if deny_count > 1:
            multi_policies.append(pol)
    multi_policies.sort()
    if args.limit:
        multi_policies = multi_policies[: args.limit]

    planned = []
    for pol in multi_policies:
        blocks = extract_rule_blocks(pol.read_text(encoding='utf-8'))
        flags = []
        for b in blocks:
            f = derive_flag_from_block(b)
            if f:
                flags.append(f)
        if not flags:
            continue
        test_path = pol.parent / TEST_FILENAME
        existing = test_path.read_text(encoding='utf-8') if test_path.exists() else ''
        additions = []
        for f in flags:
            slug = f.replace('.', '_').replace('["', '_').replace('"]', '').replace('"', '').replace("'", '')
            name = f"test_denies_when_{slug}_failing"
            # Heuristic: consider existing if either the exact flag path
            # is present OR a JSON-style key pattern is present in the test file.
            already_present = False
            if f in existing:
                already_present = True
            else:
                # controls.<policy.id> is typically represented as
                # {"controls": {"<policy.id>": ...}} in tests
                if f.startswith('controls.'):
                    ctrl_key = f.split('.', 1)[1]
                    if f'"{ctrl_key}"' in existing:
                        already_present = True
                else:
                    # Nested input flags like adr.provider_listed often
                    # appear as {"adr": {"provider_listed": ...}} in tests.
                    # Treat presence of the leaf key as sufficient evidence.
                    leaf = f.split('.')[-1]
                    if f'"{leaf}"' in existing:
                        already_present = True
            if already_present:
                continue
            failing_input = build_failing_input(flags, f)
            # Use some _ in deny pattern
            input_json = json.dumps(failing_input, separators=(',', ':'))
            block = (
                f"\n# Auto-generated granular test for {f}\n"
                f"{name} if {{\n"
                f"\tsome _ in deny with input as {input_json}\n}}\n"
            )
            additions.append(block)
        if additions:
            planned.append((test_path, additions))

    if not planned:
        print("No new granular tests needed.")
        return

    print(f"Planned additions for {len(planned)} policy test files:")
    for path, adds in planned:
        print(f" - {path}: {len(adds)} new tests")
    if not args.apply:
        print("(dry-run) Re-run with --apply to write changes.")
        return

    for path, adds in planned:
        if path.exists():
            original = path.read_text(encoding='utf-8').rstrip() + '\n'
        else:
            original = f"package rulehub.{'.'.join(path.parts[-3:-1])}\n\n"
        new_content = original + '\n'.join(adds)
        path.write_text(new_content, encoding='utf-8')
        print(f"Wrote {path}")


if __name__ == '__main__':
    main()
