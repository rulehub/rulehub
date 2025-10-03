#!/usr/bin/env python3
"""Validate all policies/**/metadata.yaml files against tools/metadata.schema.json.

Exit codes:
 0 - all metadata valid
 1 - validation errors found

Outputs a summary plus per-file errors with line context when possible.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import List

import yaml
from jsonschema import Draft7Validator, ValidationError


SCHEMA_PATH = Path("tools/metadata.schema.json")
POLICY_ROOT = Path("policies")


def load_schema():
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def iter_metadata_files():
    for p in POLICY_ROOT.glob("**/metadata.yaml"):
        yield p


def read_yaml(p: Path):
    with open(p, "r", encoding="utf-8") as f:
        try:
            return yaml.safe_load(f) or {}
        except Exception as e:
            return {"__yaml_error__": str(e)}


def format_error(e: ValidationError) -> str:
    loc = ".".join(str(x) for x in e.path) or "(root)"
    return f"[{loc}] {e.message}"


def main() -> int:
    schema = load_schema()
    validator = Draft7Validator(schema)
    total = 0
    invalid = 0
    details: List[str] = []

    for meta_file in iter_metadata_files():
        total += 1
        data = read_yaml(meta_file)
        if "__yaml_error__" in data:
            invalid += 1
            details.append(f"{meta_file}: YAML parse error: {data['__yaml_error__']}")
            continue
        errors = list(validator.iter_errors(data))
        if errors:
            invalid += 1
            for err in errors:
                details.append(f"{meta_file}: {format_error(err)}")

    if details:
        print("Validation Errors:")
        for d in details:
            print(" -", d)
    print(f"Summary: valid={total - invalid} invalid={invalid} total={total}")
    return 1 if invalid else 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
