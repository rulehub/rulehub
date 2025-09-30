import os  # noqa: F401
from pathlib import Path

import pytest  # noqa: F401

# Import functions from scripts by path
ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"

import importlib.util
import sys


def _import(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, str(path))
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    # Ensure module is visible to runtime (needed by dataclasses in Python 3.13)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


coverage_map = _import("coverage_map", TOOLS / "coverage_map.py")


def test_normalize_paths():
    n = coverage_map.normalize_paths
    assert n(None) == []
    assert n("a.yaml") == ["a.yaml"]
    assert n(["a.yaml", "b.yaml"]) == ["a.yaml", "b.yaml"]
    assert n(("x", "y")) == ["x", "y"]



def test_validate_paths_tmp(tmp_path, monkeypatch):  # type: ignore[no-untyped-def]
    # create a temp file and verify exists flag
    p = tmp_path / "foo.yaml"
    p.write_text("kind: X\n")
    idx = {"ns.id": {"path": [str(p)]}}
    res = coverage_map.validate_paths(idx)
    assert res["ns.id"][0]["exists"] is True

