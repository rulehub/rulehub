import importlib.util
import json
import sys
from pathlib import Path


def load_module():
    """Dynamically load analyze_links module from tools directory."""
    repo_root = Path(__file__).resolve().parents[2]
    mod_path = repo_root / "tools" / "analyze_links.py"
    # Ensure repository root (parent of tools/) is on sys.path for intra-tool imports
    repo_root = mod_path.parent.parent
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))
    spec = importlib.util.spec_from_file_location(
        "analyze_links", str(mod_path))
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(mod)  # type: ignore[assignment]
    return mod


def test_vendor_detection():
    mod = load_module()
    meta = [
        {"id": "p1", "links": ["https://sportradar.com/news"]},
        {"id": "p2", "links": ["https://example.com/"]},
    ]
    export = {}
    all_links = mod.build_all_links(meta, export)
    report = mod.analyze_suspicious(all_links)
    # Expected suspicious categories exist
    for cat in ["non_https", "vendor", "long", "tracking_query", "celex_pdf"]:
        assert cat in report["suspicious"], f"missing category {cat}"
    # The sportradar URL should be flagged as vendor
    assert any("sportradar.com" in u for u in report["suspicious"]["vendor"])


def test_discrepancy_detection():
    mod = load_module()
    meta = [
        {"id": "policy.a", "links": [
            "https://a.example/one", "https://b.example/two"]}
    ]
    export = {"policy.a": ["https://a.example/one", "https://c.example/three"]}
    missing_in_metadata, missing_in_export = mod.diff_metadata_export(
        meta, export)
    # export has c.example which is missing in metadata
    assert missing_in_metadata == {"policy.a": ["https://c.example/three"]}
    # metadata has b.example which is missing in export
    assert missing_in_export == {"policy.a": ["https://b.example/two"]}


def test_end_to_end_link_audit(tmp_path, monkeypatch, capsys):
    """Full flow using temp metadata + export file exercising main()."""
    # Arrange temp policy metadata
    policies_dir = tmp_path / "policies" / "p1"
    policies_dir.mkdir(parents=True)
    (policies_dir / "metadata.yaml").write_text(
        """id: p1\nlinks:\n  - https://sportradar.com/news\n  - https://example.com/a\n""",
        encoding="utf-8",
    )
    # Export has one overlapping + 1 different link to create discrepancies both ways
    (tmp_path / "links_export.json").write_text(
        json.dumps(
            {
                "policies": [
                    {
                        "id": "p1",
                        "links": [
                            "https://sportradar.com/news",
                            "https://example.com/c",
                        ],
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    # Switch CWD so analyze_links discovers our temp policies
    monkeypatch.chdir(tmp_path)
    mod = load_module()
    # Simulate CLI args
    monkeypatch.setenv("FAIL_LINK_AUDIT", "0")
    monkeypatch.setenv("PYTHONPATH", str(Path(__file__).resolve().parents[2]))
    argv_backup = sys.argv
    sys.argv = ["analyze_links.py", "--export", "links_export.json"]
    try:
        rc = mod.main()
    finally:
        sys.argv = argv_backup
    captured = capsys.readouterr().out
    assert rc == 0
    # Validate vendor detection & discrepancy counts surfaced
    assert "vendor: 1" in captured
    assert "Discrepancies: missing_in_metadata=1 policies, missing_in_export=1 policies" in captured
