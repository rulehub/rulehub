#!/usr/bin/env python3
"""Convert Spectral JSON output to SARIF v2.1.0.

This script accepts a file path or '-' to read JSON results from stdin. It
produces a SARIF file suitable for upload to GitHub code scanning.

Usage:
  python tools/convert_spectral_to_sarif.py <json-file|-> [--output file.sarif]
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict, List


def read_input(path: str) -> List[Dict[str, Any]]:
    if path == "-":
        data = sys.stdin.read()
    else:
        data = Path(path).read_text(encoding="utf-8")
    try:
        # Spectral JSON is generally either an object or an array of results.
        parsed = json.loads(data)
        if isinstance(parsed, list):
            return parsed
        # If it's an object with 'results' or similar, try to normalize
        if isinstance(parsed, dict) and "results" in parsed and isinstance(parsed["results"], list):
            return parsed["results"]
        # Fallback: wrap dict into list
        return [parsed]
    except json.JSONDecodeError:
        print("Failed to parse Spectral JSON input", file=sys.stderr)
        return []


def severity_to_level(sev: int | str) -> str:
    # Spectral severity: 0: off, 1: info, 2: warn, 3: error (varies by version)
    try:
        s = int(sev)
    except Exception:
        s = 2
    if s >= 3:
        return "error"
    if s == 2:
        return "warning"
    return "note"


def to_sarif(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    rules_index: Dict[str, Dict[str, Any]] = {}
    sarif_results = []
    for r in results:
        # Try multiple common field names used by Spectral results
        rule_id = r.get("code") or r.get(
            "ruleId") or r.get("rule") or "spectral"
        message = r.get("message") or r.get("text") or ""
        severity = r.get("severity") or r.get("level") or 2
        location = r.get("path") or (
            r.get("location") or {}).get("target") or None
        # Range info may be under 'range' with start/end having line/character
        start_line = 1
        start_column = 1
        rng = r.get("range") or r.get("location", {}).get(
            "range") if isinstance(r.get("location"), dict) else None
        if isinstance(rng, dict):
            start = rng.get("start") or {}
            start_line = start.get("line", 1)
            start_column = start.get("character", start.get("column", 1))
        sarif_rule = rules_index.get(rule_id)
        if not sarif_rule:
            sarif_rule = {
                "id": rule_id,
                "name": rule_id,
                "shortDescription": {"text": rule_id},
                "help": {"text": r.get("description", "")},
            }
            rules_index[rule_id] = sarif_rule
        sarif_results.append(
            {
                "ruleId": rule_id,
                "level": severity_to_level(severity),
                "message": {"text": message},
                "locations": [
                    {
                        "physicalLocation": {
                            "artifactLocation": {"uri": location or "?"},
                            "region": {"startLine": start_line, "startColumn": start_column},
                        }
                    }
                ],
            }
        )

    sarif = {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "spectral",
                        "informationUri": "https://meta.stoplight.io/docs/spectral/",
                        "rules": list(rules_index.values()),
                    }
                },
                "results": sarif_results,
            }
        ],
    }
    return sarif


def main(argv: List[str]) -> int:
    if not argv:
        print(
            "Usage: convert_spectral_to_sarif.py <json|-> [--output file.sarif]")
        return 2
    path = argv[0]
    output = "spectral.sarif"
    i = 1
    while i < len(argv):
        if argv[i] == "--output" and i + 1 < len(argv):
            output = argv[i + 1]
            i += 2
        else:
            i += 1
    results = read_input(path)
    sarif = to_sarif(results)
    Path(output).write_text(json.dumps(sarif, indent=2), encoding="utf-8")
    print(f"Wrote {output} with {len(results)} findings")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
