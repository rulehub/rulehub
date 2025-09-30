#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path
from typing import Iterable

import yaml


try:
    import jsonschema
except Exception:
    print("Missing dependency jsonschema. Install with: pip install jsonschema", file=sys.stderr)
    sys.exit(2)

SCHEMA_PATH = Path(__file__).parent / "schemas" / "policy-metadata.schema.json"
POLICY_ROOT = Path("policies")


def normalize_paths(p: str | Iterable[str] | None) -> list[str]:
    if p is None:
        return []
    if isinstance(p, str):
        return [p]
    if isinstance(p, (list, tuple)):
        return [str(x) for x in p]
    return []


def normalize_standard(_: dict) -> dict:
    # No-op placeholder retained for future use; schema now accepts nested standard.
    return _


def main() -> int:
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        schema = json.load(f)
    validator = jsonschema.Draft7Validator(schema)

    errors = 0
    warnings = 0
    id_index: dict[str, list[str]] = {}
    for meta in POLICY_ROOT.glob("**/metadata.yaml"):
        with open(meta, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        # Validate schema (supports flat or nested standard via JSON Schema oneOf)
        for err in sorted(validator.iter_errors(data), key=lambda e: e.path):
            print(f"Schema error in {meta}: {err.message}")
            errors += 1
        # Collect ids for duplicate detection
        pid = data.get("id")
        if pid:
            id_index.setdefault(pid, []).append(str(meta))
        # Validate presence of 'path' and file paths exist
        if "path" not in data:
            print(f"Missing required 'path' in {meta}")
            errors += 1
        paths = normalize_paths(data.get("path"))
        if len(paths) == 0:
            print(
                (
                    f"Warning: Empty path list in {meta}. "
                    "Replace placeholder path: [] with actual file path(s) when available."
                )
            )
            # Optional strict mode via env var
            if os.getenv("STRICT_EMPTY_PATHS") == "1":
                errors += 1
            else:
                warnings += 1
        for p in paths:
            if not os.path.exists(p):
                print(f"Path not found in {meta}: {p}")
                errors += 1

    # Fail on duplicate policy IDs across repository
    for pid, files in sorted(id_index.items()):
        if len(files) > 1:
            print(
                "Duplicate policy id '{pid}' found in multiple files: {files}".format(
                    pid=pid, files=", ".join(files)
                )
            )
            # Count each extra occurrence as an error
            errors += (len(files) - 1)

    if errors:
        print(f"Validation failed with {errors} error(s).", file=sys.stderr)
        return 1
    if warnings:
        print(f"Completed with {warnings} warning(s).")
    print("All metadata files are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
