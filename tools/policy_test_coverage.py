#!/usr/bin/env python3
"""Compute enriched policy test coverage for Gatekeeper (Rego) policies.

Metrics:
1. Directory coverage: percentage of policy directories containing a
    `policy_test.rego` file.
2. Dual-direction tests: at least one failing (deny) scenario AND one passing scenario.
3. Multi-rule adequacy: for policies with multiple deny rules, ensure enough
    deny-oriented test assertions (heuristic).

Heuristics (fast, no OPA parse):
 - Count deny rules by regex r'^\\s*deny\\b' in policy.rego.
 - Deny assertion if line matches r'deny\\[' or r'count(deny) >'.
 - Passing if line has 'count(deny) == 0' or 'not deny['.

Output JSON (dist/policy-test-coverage.json):
{
    tested,total,percent,
    dual_direction:{count,percent},
    multi_rule:{policies_with_multi,adequate,count_inadequate,list_inadequate:[...]},
    details:[{policy,has_test,deny_rule_count,deny_test_assertions,has_pass_assertion,adequate_multi_rule,dual_direction}]
}

NOTE: This remains heuristic; enhancements can replace regex with AST parsing later.
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path
from typing import TypedDict


POLICIES_ROOT = Path("policies")
OUT_JSON = Path("dist/policy-test-coverage.json")


class PolicyDetail(TypedDict):
    policy: str
    test: str | None
    has_test: bool
    deny_rule_count: int
    deny_test_assertions: int
    has_pass_assertion: bool
    dual_direction: bool
    adequate_multi_rule: bool


class RowDetail(TypedDict):
    policy: str
    deny_rules: int
    deny_tests: int
    has_pass: bool
    issue: str


def main() -> None:
    policy_dirs = [p for p in POLICIES_ROOT.glob("**/policy.rego")]
    if not policy_dirs:
        print("No policy.rego files found")
        return
    total = len(policy_dirs)
    tested = 0
    dual_direction = 0
    multi_rule_with_multi = 0
    adequate_multi = 0
    inadequate_multi_list: list[dict] = []
    # Historical violation[] tracking removed (baseline starts at deny[] usage only)
    details: list[PolicyDetail] = []

    deny_rule_re = re.compile(r'^\s*deny\b')
    # Pass assertion heuristics now also detect direct allow invocation lines like:
    #   allow with input as {...}
    # which are the predominant pattern in this repo's test files.
    pass_assert_re = re.compile(
        r'(count\(\s*deny\s*\)\s*==\s*0)'
        r'|(?:count\(\s*deny\s*\)\s+with\s+input\s+as\s+\w+\s*==\s*0)'
        r'|(?:not\s+deny\[)'
        r'|(?:deny\s*==\s*\[\])'
        r'|(?:count\(\s*deny\s*\)\s*<=\s*0)'
        r'|(?:\ballow\s+with\s+input\s+as\b)'
    )
    deny_assert_re = re.compile(
        r'(?:deny\[)'
        r'|(?:some\s+deny)'
        r'|(?:some\s+_\s+in\s+deny)'
        r'|(?:count\(\s*deny\s*\)\s*>\s*0)'
        r'|(?:count\(\s*deny\s*\)\s*>=\s*1)'
        r'|(?:count\(\s*deny\s*\)\s*==\s*[1-9])'
        r'|(?:count\(\s*deny\s*\)\s+with\s+input\s+as\s+\w+\s*==\s*[1-9])'
    )
    # No violation[] detection needed beyond deny[] baseline

    use_opa = shutil.which("opa") is not None
    for pol in policy_dirs:
        test_file = pol.parent / "policy_test.rego"
        has_test = test_file.exists()
        if has_test:
            tested += 1
    # Analyze policy deny rule count
        policy_text = pol.read_text(encoding='utf-8')
        deny_rule_count = sum(
            1 for line in policy_text.splitlines() if deny_rule_re.search(line)
        )
        # Optional: refine deny rule count via AST (opa parse -f json) if available
        if use_opa:
            try:
                proc = subprocess.run(
                    ["opa", "parse", "-f", "json", str(pol)],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                ast = json.loads(proc.stdout)
                # Traverse to count rule heads named 'deny'

                def _count(node):  # type: ignore[return-any]
                    if isinstance(node, dict):
                        c = 0
                        if node.get("type") == "Rule" and node.get("head", {}).get("name") == "deny":
                            c += 1
                        for v in node.values():
                            c += _count(v)
                        return c
                    if isinstance(node, list):
                        return sum([_count(n) for n in node])
                    return 0
                ast_count = _count(ast)
                if ast_count > 0:
                    deny_rule_count = ast_count
            except Exception:
                pass
    # Mixed violation/deny concept removed
        deny_test_assertions = 0
        has_pass_assertion = False
    # test-level violation[] detection removed
        if has_test:
            t_text = test_file.read_text(encoding='utf-8')
            # Count deny assertions heuristically
            lines = t_text.splitlines()
            deny_test_assertions = sum(
                1 for line in lines if deny_assert_re.search(line)
            )
            has_pass_assertion = any(
                pass_assert_re.search(line) for line in lines
            )
            # violation[] detection removed
        is_dual = has_test and deny_test_assertions > 0 and has_pass_assertion
        if is_dual:
            dual_direction += 1
        adequate = True
        if deny_rule_count > 1:
            multi_rule_with_multi += 1
            # require at least deny_rule_count + 1 deny assertions (for edge cases)
            if deny_test_assertions < deny_rule_count + 1:
                adequate = False
                inadequate_multi_list.append({
                    "policy": str(pol),
                    "deny_rules": deny_rule_count,
                    "deny_test_assertions": deny_test_assertions,
                })
            else:
                adequate_multi += 1
        details.append({
            "policy": str(pol),
            "test": str(test_file) if has_test else None,
            "has_test": has_test,
            "deny_rule_count": deny_rule_count,
            "deny_test_assertions": deny_test_assertions,
            "has_pass_assertion": has_pass_assertion,
            "dual_direction": is_dual,
            "adequate_multi_rule": adequate,
            # historical violation[] fields removed
        })
    pct = round(100 * tested / total, 2)
    dual_pct = round(100 * dual_direction / total, 2)
    print(f"Policy test coverage (presence): {tested}/{total} ({pct}%)")
    print(
        f"Dual-direction policies (deny + pass assertion): {dual_direction}/{total} ({dual_pct}%)")
    if inadequate_multi_list:
        print("Policies with inadequate multi-rule test depth:")
        for item in inadequate_multi_list:
            print(
                " - {policy}: deny_rules={dr} deny_test_assertions={dta}".format(
                    policy=item['policy'], dr=item['deny_rules'], dta=item['deny_test_assertions']
                )
            )
    # Prioritized improvement list (exclude already adequate & single-rule)
    improve_dual = [d for d in details if d['has_test']
                    and not d['dual_direction']]
    improve_multi = [i['policy'] for i in inadequate_multi_list]
    if improve_dual or improve_multi:
        print("\nTest Improvement Priorities:")
        if improve_multi:
            print("  1. Add additional deny assertions to multi-rule policies:")
            for pol in improve_multi[:20]:
                print(f"     - {pol}")
            if len(improve_multi) > 20:
                print(f"     ... {len(improve_multi)-20} more")
        if improve_dual:
            print("  2. Add complementary pass/deny scenarios to achieve dual-direction:")
            # Sort by highest deny_rule_count to tackle complex policies first
            improve_dual_sorted = sorted(
                improve_dual, key=lambda d: d['deny_rule_count'], reverse=True)
            for d in improve_dual_sorted[:20]:
                pass_flag = 'yes' if d['has_pass_assertion'] else 'no'
                print(
                    f"     - {d['policy']} (deny_rules={d['deny_rule_count']}, "
                    f"deny_tests={d['deny_test_assertions']}, pass={pass_flag})"
                )
            if len(improve_dual_sorted) > 20:
                print(f"     ... {len(improve_dual_sorted)-20} more")
    # prior violation[] reporting removed
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_JSON, 'w', encoding='utf-8') as f:
        json.dump({
            "tested": tested,
            "total": total,
            "percent": pct,
            "dual_direction": {"count": dual_direction, "percent": dual_pct},
            "multi_rule": {
                "policies_with_multi": multi_rule_with_multi,
                "adequate": adequate_multi,
                "count_inadequate": len(inadequate_multi_list),
                "list_inadequate": inadequate_multi_list,
            },
            # prior violation[] dimension removed
            "details": details,
        }, f, indent=2)
    print(f"Wrote {OUT_JSON}")

    # --- Markdown priorities report -------------------------------------
    priorities_md = Path("dist/policy-test-priorities.md")
    priorities_md.parent.mkdir(parents=True, exist_ok=True)
    dual_missing = [d for d in details if d['has_test']
                    and not d['dual_direction']]
    # Combine issues per policy
    rows: list[RowDetail] = []
    for d in dual_missing:
        issue_parts = []
        if d['deny_rule_count'] > 1 and d['deny_test_assertions'] < d['deny_rule_count']:
            issue_parts.append('add deny assertions')
        if not d['has_pass_assertion']:
            issue_parts.append('add pass test')
        issue = ', '.join(
            issue_parts) if issue_parts else 'add complementary scenario'
        rows.append({
            'policy': d['policy'],
            'deny_rules': d['deny_rule_count'],
            'deny_tests': d['deny_test_assertions'],
            'has_pass': d['has_pass_assertion'],
            'issue': issue,
        })
    # Include multi-rule inadequate ones that might already be dual missing
    inadequate_lookup = {i['policy']: i for i in inadequate_multi_list}
    # Sort: primary by deny_rules desc, then by deny_tests asc
    rows_sorted = sorted(
        rows, key=lambda r: (-r['deny_rules'], r['deny_tests']))
    with open(priorities_md, 'w', encoding='utf-8') as mf:
        mf.write("# Policy Test Improvement Priorities\n\n")
        mf.write("Generated by tools/policy_test_coverage.py\n\n")
        mf.write(
            "Presence coverage: {tested}/{total} ({pct}%). Dual-direction: "
            "{dual}/{total} ({dual_pct}%).\n\n".format(
                tested=tested,
                total=total,
                pct=pct,
                dual=dual_direction,
                dual_pct=dual_pct,
            )
        )
        if not rows_sorted:
            mf.write("All policies have dual-direction coverage.\n")
        else:
            mf.write(
                "| Policy | Deny Rules | Deny Test Assertions | Has Pass | Issue |\n")
            mf.write(
                "|--------|------------|----------------------|----------|-------|\n")
            for r in rows_sorted:
                has_pass = 'yes' if r['has_pass'] else 'no'
                mf.write(
                    "| {policy} | {deny_rules} | {deny_tests} | {has_pass} | {issue} |\n".format(
                        policy=r['policy'],
                        deny_rules=r['deny_rules'],
                        deny_tests=r['deny_tests'],
                        has_pass=has_pass,
                        issue=r['issue'],
                    )
                )
        if inadequate_lookup:
            mf.write("\n## Multi-rule Inadequate Details\n\n")
            mf.write("| Policy | Deny Rules | Deny Test Assertions | Needed |\n")
            mf.write("|--------|------------|----------------------|--------|\n")
            for pol, meta in sorted(inadequate_lookup.items(), key=lambda kv: -kv[1]['deny_rules']):
                needed = meta['deny_rules'] - meta['deny_test_assertions']
                mf.write(
                    f"| {pol} | {meta['deny_rules']} | {meta['deny_test_assertions']} | +{needed} deny tests |\n")
    print(f"Wrote {priorities_md}")


if __name__ == "__main__":
    main()
