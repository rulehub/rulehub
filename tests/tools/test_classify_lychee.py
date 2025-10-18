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


def _write(tmp_path, payload):  # type: ignore[no-untyped-def]
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


def test_fail_map_schema(tmp_path):  # type: ignore[no-untyped-def]
    js = _write(tmp_path, {
        "errors": 2,
        "fail_map": {
            "README.md": [
                {"status": 404, "link": "https://example.com/missing"},
                {"status": 429, "link": "https://ratelimited.example"},
            ]
        }
    })
    # One hard (404) and one soft (429) -> exit 1
    assert clf.main(str(js)) == 1


def test_failures_array_schema(tmp_path):  # type: ignore[no-untyped-def]
    js = _write(tmp_path, {
        "failures": [
            {"status": 500, "link": "https://server-error.example"},
            {"status": 404, "link": "https://missing.example"},
        ]
    })
    # Contains a hard 404 -> exit 1
    assert clf.main(str(js)) == 1


def test_numeric_errors_only(tmp_path):  # type: ignore[no-untyped-def]
    # Numeric errors with no detail should be treated conservatively as hard
    js = _write(tmp_path, {"errors": 3})
    assert clf.main(str(js)) == 1


def test_missing_status_treated_hard(tmp_path):  # type: ignore[no-untyped-def]
    js = _write(tmp_path, {
        "errors": [
            {"link": "https://unknown-status.example"}
        ]
    })
    assert clf.main(str(js)) == 1
