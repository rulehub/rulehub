#!/usr/bin/env python3
"""Run yamllint producing SARIF output.

This utility executes `yamllint -f json` against the repository root (or a
provided path) and converts findings to a SARIF v2.1.0 file so results can be
uploaded to GitHub code scanning.

Usage:
  python tools/convert_yamllint_to_sarif.py [path] [--output yamllint.sarif]

Exit code:
  Mirrors yamllint exit code (non‑zero if issues). The SARIF file is written
  regardless (unless a hard failure occurs) so upload should still proceed.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List


def run_yamllint(target: str) -> tuple[int, List[Dict[str, Any]]]:
    """Run yamllint with JSON output and return (exit_code, findings)."""
    try:
        completed = subprocess.run(
            [
                sys.executable,
                "-m",
                "yamllint",
                "-f",
                "json",
                target,
            ],
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        print("yamllint not installed; please pip install yamllint", file=sys.stderr)
        return 2, []

    findings: List[Dict[str, Any]] = []
    if completed.stdout.strip():
        try:
            data = json.loads(completed.stdout)
            # yamllint json: {"path/file.yaml": [{line, column, level, message, rule, ...}, ...], ...}
            for path, issues in data.items():
                for issue in issues:
                    issue["path"] = path
                    findings.append(issue)
        except json.JSONDecodeError:
            print("Failed to parse yamllint JSON output", file=sys.stderr)
    return completed.returncode, findings


def severity_to_level(level: str) -> str:
    mapping = {
        "error": "error",
        "warning": "warning",
        "info": "note",
    }
    return mapping.get(level.lower(), "note")


def to_sarif(findings: List[Dict[str, Any]]) -> Dict[str, Any]:
    rules_index: Dict[str, Dict[str, Any]] = {}
    results = []
    for f in findings:
        rule_id = f.get("rule", "yamllint")
        if rule_id not in rules_index:
            rules_index[rule_id] = {
                "id": rule_id,
                "name": rule_id,
                "shortDescription": {"text": rule_id},
                "help": {"text": f.get("desc", "")},
            }
        results.append(
            {
                "ruleId": rule_id,
                "level": severity_to_level(f.get("level", "warning")),
                "message": {"text": f.get("message", "")},
                "locations": [
                    {
                        "physicalLocation": {
                            "artifactLocation": {"uri": f.get("path")},
                            "region": {
                                "startLine": f.get("line", 1),
                                "startColumn": f.get("column", 1),
                            },
                        }
                    }
                ],
            }
        )

    sarif: Dict[str, Any] = {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "yamllint",
                        "informationUri": "https://yamllint.readthedocs.io/",
                        "rules": list(rules_index.values()),
                    }
                },
                "results": results,
            }
        ],
    }
    return sarif


def main(argv: List[str]) -> int:
    target = "."
    output = "yamllint.sarif"
    i = 0
    while i < len(argv):
        if argv[i] == "--output" and i + 1 < len(argv):
            output = argv[i + 1]
            i += 2
        else:
            target = argv[i]
            i += 1

    code, findings = run_yamllint(target)
    sarif = to_sarif(findings)
    Path(output).write_text(json.dumps(sarif, indent=2), encoding="utf-8")
    print(f"Wrote {output} with {len(findings)} findings")
    return code


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
