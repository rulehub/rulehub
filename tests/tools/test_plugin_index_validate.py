import json
from pathlib import Path

import pytest

from tools import plugin_index_validate as piv


def write(tmp_path: Path, rel: str, data: dict):
    p = tmp_path / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data), encoding="utf-8")
    return p


def load_schema() -> dict:
    schema_p = Path("tools/schemas/plugin-index.schema.json")
    return json.loads(schema_p.read_text(encoding="utf-8"))


def test_valid_index(tmp_path: Path):
    schema = load_schema()
    # Build a minimal valid index according to the schema
    packages = [
        {
            "id": "pci.storage_encryption",
            "name": "Storage encryption",
            "standard": "PCI DSS",
            "version": "3.2",
            "coverage": ["PCI 3.1"],
        }
    ]
    idx = {"packages": packages}
    schema_p = write(tmp_path, "schema.json", schema)
    idx_p = write(tmp_path, "index.json", idx)

    valid, errors = piv.validate_index(schema_p, idx_p)
    assert valid is True
    assert errors == []


def test_invalid_index_reports_pointer(tmp_path: Path):
    schema = load_schema()
    # Missing required 'packages' -> top level error
    idx = {"not_packages": []}
    schema_p = write(tmp_path, "schema.json", schema)
    idx_p = write(tmp_path, "index.json", idx)

    valid, errors = piv.validate_index(schema_p, idx_p)
    assert valid is False
    # Expect at least one error with pointer '/'
    pointers = [e["pointer"] for e in errors]
    assert "/" in pointers or any(p.startswith("/") for p in pointers)
