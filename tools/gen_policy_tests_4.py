#!/usr/bin/env python3
"""Generate policy_test.rego for policies with exactly 4 deny rules.

Creates a minimal test file containing:
 - an allow (passing) case
 - four deny assertions (failing cases) derived from each deny block

Safety:
 - Does not overwrite existing test files unless --force is provided.
 - If --policy is provided and that policy does not have exactly 4 deny
   rules the script aborts with non-zero exit.

This follows repository conventions used by other tooling in `tools/`.
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
INPUT_FLAG_RE = re.compile(
    r"input\.([a-zA-Z0-9_\.\[\]\"]+)\s*(==\s*(true|false))?")
NOT_INPUT_RE = re.compile(r"not\s+input\.([a-zA-Z0-9_\.\[\]\"]+)")
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
            brace_depth += line.count("{")
            brace_depth -= line.count("}")
            if brace_depth < 0 or line.strip() == "}":
                in_block = False
                blocks.append(current)
                continue
            current.append(line)
    return blocks


def derive_flag_from_block(block_lines: List[str]) -> str | None:
    joined = " \n".join(block_lines)
    m = INPUT_FLAG_RE.search(joined)
    if m:
        return m.group(1)
    n = NOT_INPUT_RE.search(joined)
    if n:
        return n.group(1)
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
    root: Dict[str, Any] = {"controls": {}}
    for f in flags:
        is_target = f == target
        value: Any = False if is_target else True
        segs = f.split('.')
        if segs[0] == 'controls':
            remainder = segs[1:]
            if not remainder:
                continue
            _assign(root.setdefault('controls', {}), remainder, value)
        else:
            _assign(root, segs, value)
    return root


def slug_of_flag(f: str) -> str:
    return f.replace('.', '_').replace('["', '_').replace('"]', '').replace('"', '').replace("'", '')


def make_package_line(pol_path: Path) -> str:
    # expect policies/<domain>/<policy_id>/policy.rego
    parts = pol_path.parts
    # find 'policies' in path
    try:
        idx = parts.index('policies')
        domain = parts[idx + 1]
        pid = parts[idx + 2]
        return f"package rulehub.{domain}.{pid}\n"
    except Exception:
        # fallback: create package from parent folders
        pkg = '.'.join(pol_path.parent.parts[-2:])
        return f"package rulehub.{pkg}\n"


def gen_for_policy(pol: Path, apply: bool, force: bool) -> bool:
    text = pol.read_text(encoding='utf-8')
    deny_count = sum(1 for line in text.splitlines()
                     if re.match(r'^\s*deny\b', line))
    if deny_count != 4:
        raise SystemExit(
            f"Policy {pol} has {deny_count} deny rules (expected 4); aborting")

    blocks = extract_rule_blocks(text)
    flags: List[str] = []
    for b in blocks:
        f = derive_flag_from_block(b)
        if f:
            flags.append(f)
    # If we couldn't derive four flags, create generic control-based flags
    if len(flags) < 4:
        ctrl_key = '.'.join(pol.parent.parts[-2:])
        # ensure we have four distinct control keys
        flags = [
            f"controls.{ctrl_key}",
            f"controls.{ctrl_key}.alt",
            f"controls.{ctrl_key}.alt2",
            f"controls.{ctrl_key}.alt3",
        ]

    test_path = pol.parent / TEST_FILENAME
    if test_path.exists() and not force:
        print(f"Skipping {pol}: {test_path} exists (use --force to overwrite)")
        return False

    pkg_line = make_package_line(pol)
    # For allow case, set all flags to True
    allow_input: Dict[str, Any] = {}
    for f in flags:
        segs = f.split('.')
        if segs[0] == 'controls':
            _assign(allow_input.setdefault('controls', {}), segs[1:], True)
        else:
            _assign(allow_input, segs, True)

    allow_json = json.dumps(allow_input, separators=(',', ':'))

    parts: List[str] = [pkg_line, "\n"]
    parts.append("test_allow_when_compliant if {\n")
    parts.append(f"\tallow with input as {allow_json}\n")
    parts.append("}\n\n")

    # Four deny tests
    for i, f in enumerate(flags, start=1):
        slug = slug_of_flag(f)
        name = f"test_denies_when_{slug}_failing"
        failing_input = build_failing_input(flags, f)
        input_json = json.dumps(failing_input, separators=(',', ':'))
        parts.append(f"# Auto-generated deny test for {f}\n")
        parts.append(f"{name} if {{\n")
        parts.append(f"\tcount(deny) > 0 with input as {input_json}\n")
        parts.append("}\n\n")

    content = ''.join(parts)
    if not apply:
        print(f"(dry-run) Would write {test_path}")
        return True

    # write file
    test_path.write_text(content, encoding='utf-8')
    print(f"Wrote {test_path}")
    return True


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--policies-root', default='policies',
                    help='Policies root directory')
    ap.add_argument('--apply', action='store_true', help='Write changes')
    ap.add_argument('--force', action='store_true',
                    help='Overwrite existing test files')
    ap.add_argument(
        '--policy', help='Path to a specific policy.rego to target')
    ap.add_argument('--limit', type=int, default=None)
    args = ap.parse_args(argv)

    policies_root = Path(args.policies_root)
    if not policies_root.exists():
        print(f"Policies root {policies_root} does not exist")
        return 2

    policy_files = list(policies_root.glob('**/policy.rego'))
    if args.policy:
        pol_path = Path(args.policy)
        # If provided a relative path under policies_root, resolve
        if not pol_path.is_absolute():
            pol_path = policies_root / pol_path
        if not pol_path.exists():
            print(f"Policy {pol_path} not found")
            return 2
        # Only process this and abort on deny count mismatch per acceptance
        try:
            gen_for_policy(pol_path, apply=args.apply, force=args.force)
        except SystemExit as e:
            print(str(e))
            return 3
        return 0

    # Otherwise process all policies with exactly 4 deny rules
    processed = 0
    for pol in sorted(policy_files):
        text = pol.read_text(encoding='utf-8')
        deny_count = sum(1 for line in text.splitlines()
                         if re.match(r'^\s*deny\b', line))
        if deny_count != 4:
            continue
        if args.limit and processed >= args.limit:
            break
        try:
            gen_for_policy(pol, apply=args.apply, force=args.force)
            processed += 1
        except SystemExit as e:
            print(f"Skipping {pol}: {e}")
            continue

    if processed == 0:
        print("No policies with exactly 4 deny rules found (or nothing written in dry-run)")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
