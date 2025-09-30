import importlib.util
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / ".github" / "scripts" / "classify_lychee.py"


def _import(name: str, path: Path):  # reuse minimal dynamic import
    spec = importlib.util.spec_from_file_location(name, str(path))
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[attr-defined]
    return mod


clf = _import("classify_lychee", SCRIPT)


def _write(tmp_path: Path, payload: dict) -> Path:
    p = tmp_path / "lychee.json"
    p.write_text(json.dumps(payload))
    return p


def test_no_errors(tmp_path):  # type: ignore[no-untyped-def]
    js = _write(tmp_path, {"errors": []})
    assert clf.main(str(js)) == 0


def test_soft_errors(tmp_path):  # type: ignore[no-untyped-def]
    js = _write(tmp_path, {"errors": [
        {"status": 500, "link": "https://example.com",
            "source": "README.md", "line": 10},
        {"status": 429, "link": "https://ratelimited.example",
            "source": "docs/x.md", "line": 5},
    ]})
    assert clf.main(str(js)) == 0


def test_hard_errors(tmp_path):  # type: ignore[no-untyped-def]
    js = _write(tmp_path, {"errors": [
        {"status": 404, "link": "https://example.com/missing",
            "source": "README.md", "line": 7},
        {"status": 429, "link": "https://ratelimited.example",
            "source": "docs/x.md", "line": 5},
    ]})
    assert clf.main(str(js)) == 1


def test_malformed(tmp_path):  # type: ignore[no-untyped-def]
    bad = tmp_path / "lychee.json"
    bad.write_text("not json")
    assert clf.main(str(bad)) == 2
