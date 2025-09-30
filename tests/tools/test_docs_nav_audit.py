from pathlib import Path
import importlib.util
import sys


def _load_dna_module():
    repo_root = Path(__file__).resolve().parents[2]
    mod_path = repo_root / "tools" / "docs_nav_audit.py"
    spec = importlib.util.spec_from_file_location(
        "tools.docs_nav_audit", str(mod_path))
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module from {mod_path}")
    mod = importlib.util.module_from_spec(spec)
    assert isinstance(spec.name, str)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)  # type: ignore
    return mod


dna = _load_dna_module()


def test_flatten_nav_simple():
    nav = [
        "index.md",
        {"Getting Started": "getting-started.md"},
        {"Section": [
            {"Sub": "sub/page.md"},
            "standalone.md",
        ]},
    ]
    paths = dna.flatten_nav(nav)
    assert Path("index.md") in paths
    assert Path("getting-started.md") in paths
    assert Path("sub/page.md") in paths
    assert Path("standalone.md") in paths


def test_generate_report_and_write(tmp_path: Path):
    nav_paths = {Path("index.md"), Path("a.md"), Path("missing-in-files.md")}
    # docs files present
    docs = {Path("index.md"), Path("b.md"), Path("a.md")}

    missing, orphan, broken = dna.generate_report(nav_paths, docs)
    # missing = docs - nav = b.md
    assert missing == ["b.md"]
    # orphan mirrors missing
    assert orphan == ["b.md"]
    # broken = nav - docs = missing-in-files.md
    assert broken == ["missing-in-files.md"]

    out = tmp_path / "out.md"
    dna.write_markdown_report(out, missing, orphan, broken)
    text = out.read_text(encoding="utf-8")
    assert "## Missing In Nav" in text
    assert "b.md" in text
    assert "missing-in-files.md" in text


def test_write_empty_sections(tmp_path: Path):
    out = tmp_path / "empty.md"
    dna.write_markdown_report(out, [], [], [])
    t = out.read_text(encoding="utf-8")
    # acceptance: show 'None' when empty
    assert "None" in t
