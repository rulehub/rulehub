#!/usr/bin/env python3
"""Enumerate policies, count deny rules vs test assertions, suggest generator commands.

Produces:
 - dist/coverage/phase1_medtech.md
 - dist/coverage/phase1_medtech.json

Columns: policy_path | deny_rules | deny_test_assertions | missing_count | suggested_command
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Dict, List


def count_deny_rules(text: str) -> int:
    return sum(1 for line in text.splitlines() if re.match(r"^\s*deny\b", line))


def count_test_assertions(dirpath: Path) -> int:
    # count occurrences of count(deny) across rego files in the same directory
    count = 0
    for f in dirpath.glob("*.rego"):
        try:
            txt = f.read_text(encoding='utf-8')
        except Exception:
            continue
        count += txt.count("count(deny)")
    return count


def suggest_command(policies_root: Path, pol_path: Path, deny: int, assertions: int) -> str:
    missing = deny - assertions
    if missing <= 0:
        return ""
    # prefer generator matching the policy deny count if available
    if deny in (2, 3, 4):
        gen = f"tools/gen_policy_tests_{deny}.py"
        rel = pol_path.relative_to(policies_root)
        # if there are existing assertions, warn that generator will overwrite
        if assertions == 0:
            return f"python3 {gen} --policies-root {policies_root} --policy {rel}"
        return f"python3 {gen} --policies-root {policies_root} --policy {rel} --apply --force"
    # fallback: no exact generator available, suggest manual edit
    return "# No generator available for this deny count; add missing assertions manually"


def build_rows(policies_root: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    policy_files = list(policies_root.glob("**/policy.rego"))
    for pol in sorted(policy_files):
        try:
            text = pol.read_text(encoding='utf-8')
        except Exception:
            continue
        deny = count_deny_rules(text)
        assertions = count_test_assertions(pol.parent)
        missing = deny - assertions
        cmd = suggest_command(policies_root, pol, deny, assertions)
        rows.append({
            "policy_path": str(pol),
            "deny_rules": deny,
            "deny_test_assertions": assertions,
            "missing_count": missing if missing > 0 else 0,
            "suggested_command": cmd,
        })
    return rows


def write_outputs(rows: List[Dict[str, Any]], out_dir: Path, phase_name: str) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    json_path = out_dir / f"{phase_name}.json"
    md_path = out_dir / f"{phase_name}.md"
    json_path.write_text(json.dumps(rows, indent=2), encoding='utf-8')

    # write md table
    headers = ["policy_path", "deny_rules", "deny_test_assertions",
               "missing_count", "suggested_command"]
    lines: List[str] = []
    lines.append("| " + " | ".join(headers) + " |")
    lines.append("| " + " | ".join(["---"] * len(headers)) + " |")
    for r in rows:
        vals = [str(r.get(h, "")) for h in headers]
        # escape pipe characters in suggested_command
        vals = [v.replace("|", "\\|") for v in vals]
        lines.append("| " + " | ".join(vals) + " |")
    md_path.write_text("\n".join(lines) + "\n", encoding='utf-8')


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--policies-root', default='policies')
    ap.add_argument('--out-dir', default='dist/coverage')
    ap.add_argument('--phase-name', default='phase1_medtech')
    args = ap.parse_args(argv)

    policies_root = Path(args.policies_root)
    if not policies_root.exists():
        print(f"Policies root {policies_root} does not exist")
        return 2

    rows = build_rows(policies_root)
    out_dir = Path(args.out_dir)
    write_outputs(rows, out_dir, args.phase_name)
    print(f"Wrote outputs to {out_dir}/{args.phase_name}.{{md,json}}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
