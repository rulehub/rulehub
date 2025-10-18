#!/usr/bin/env python3
"""
Validate dist/index.json against tools/schemas/plugin-index.schema.json.

Intended to be invoked from CI or local development. Exits non-zero on failure.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict


try:
    import jsonschema  # type: ignore
except Exception as e:  # pragma: no cover - handled by caller ensure script
    print(f"FATAL: jsonschema not available: {e}", file=sys.stderr)
    sys.exit(2)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    schema_path = repo_root / "tools/schemas/plugin-index.schema.json"
    index_path = repo_root / "dist/index.json"

    if not schema_path.is_file():
        print(f"Schema not found: {schema_path}", file=sys.stderr)
        return 2
    if not index_path.is_file():
        print(f"Index not found: {index_path}", file=sys.stderr)
        return 2

    with schema_path.open("r", encoding="utf-8") as f:
        schema: Dict[str, Any] = json.load(f)
    with index_path.open("r", encoding="utf-8") as f:
        data: Any = json.load(f)

    # jsonschema types accept Any for schema; explicit annotations avoid mypy Unknown
    jsonschema.validate(instance=data, schema=schema)  # type: ignore[no-untyped-call]
    print("dist/index.json schema validation OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
