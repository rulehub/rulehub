#!/usr/bin/env python3
"""Validate `dist/index.json` against the Backstage plugin index JSON Schema.

Produces a human-friendly markdown report at `dist/integrity/plugin_index_validation.md`
and optionally a machine-readable JSON errors file.

Usage: python3 tools/plugin_index_validate.py [--schema SCHEMA] [--index INDEX]
                                              [--out-md OUT_MD] [--out-json OUT_JSON]

Exit codes: 0 = valid (or no data), 2 = validation errors, 3 = IO/parse/schema issues
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Tuple


try:
    import jsonschema
except Exception:  # pragma: no cover - import tested indirectly in CI
    jsonschema = None  # type: ignore


def _json_pointer_from_path(path) -> str:
    """Convert jsonschema error.absolute_path (a deque/tuple) to a JSON Pointer."""
    if not path:
        return "/"
    parts = []
    for p in path:
        parts.append(str(p))
    return "/" + "/".join(parts)


def validate_index(schema_path: Path, index_path: Path) -> Tuple[bool, List[Dict[str, Any]]]:
    """Validate index JSON against schema.

    Returns (is_valid, errors). `errors` is a list of dicts with keys: pointer, message, instance
    """
    if jsonschema is None:
        raise RuntimeError("jsonschema not installed")

    if not schema_path.exists():
        raise FileNotFoundError(f"Schema not found: {schema_path}")
    if not index_path.exists():
        raise FileNotFoundError(f"Index not found: {index_path}")

    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    data = json.loads(index_path.read_text(encoding="utf-8"))

    validator = jsonschema.Draft7Validator(schema)
    errors = []
    for err in sorted(validator.iter_errors(data), key=lambda e: e.path):
        pointer = _json_pointer_from_path(err.absolute_path)
        errors.append(
            {
                "pointer": pointer,
                "message": err.message,
                "schema_path": list(err.absolute_schema_path),
                "instance": err.instance,
            }
        )

    return (len(errors) == 0, errors)


def write_reports(is_valid: bool, errors: List[Dict[str, Any]], out_md: Path, out_json: Path | None) -> None:
    out_md.parent.mkdir(parents=True, exist_ok=True)
    with open(out_md, "w", encoding="utf-8") as f:
        f.write("# Plugin Index Validation Report\n\n")
        if is_valid:
            f.write("Schema valid\n")
        else:
            f.write("Schema validation errors:\n\n")
            for e in errors:
                f.write(f"- Pointer: `{e.get('pointer')}`\n  - Message: {e.get('message')}\n")

    if out_json:
        with open(out_json, "w", encoding="utf-8") as fj:
            json.dump({"valid": is_valid, "errors": errors}, fj, indent=2, ensure_ascii=False)


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="plugin_index_validate")
    parser.add_argument("--schema", type=Path, default=Path("tools/schemas/plugin-index.schema.json"))
    parser.add_argument("--index", type=Path, default=Path("dist/index.json"))
    parser.add_argument("--out-md", type=Path, default=Path("dist/integrity/plugin_index_validation.md"))
    parser.add_argument("--out-json", type=Path, default=Path("dist/integrity/plugin_index_validation.json"))
    parser.add_argument("--no-json", action="store_true", help="Do not write JSON errors file")
    args = parser.parse_args(argv)

    try:
        is_valid, errors = validate_index(args.schema, args.index)
    except FileNotFoundError as e:
        # Write an informative markdown and return non-zero
        args.out_md.parent.mkdir(parents=True, exist_ok=True)
        with open(args.out_md, "w", encoding="utf-8") as f:
            f.write("# Plugin Index Validation Report\n\n")
            f.write(f"Missing file: {e}\n")
        print(e)
        return 3
    except json.JSONDecodeError as e:
        args.out_md.parent.mkdir(parents=True, exist_ok=True)
        with open(args.out_md, "w", encoding="utf-8") as f:
            f.write("# Plugin Index Validation Report\n\n")
            f.write(f"JSON parse error: {e}\n")
        print(e)
        return 3
    except RuntimeError as e:
        print(e)
        return 3

    out_json = None if args.no_json else args.out_json
    write_reports(is_valid, errors, args.out_md, out_json)

    if is_valid:
        print("Schema valid")
        return 0
    else:
        print("Schema validation errors:")
        for e in errors:
            print(f"- {e.get('pointer')}: {e.get('message')}")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
