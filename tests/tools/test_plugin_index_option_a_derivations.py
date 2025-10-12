import json
import sys
from pathlib import Path
from typing import Any, List, Dict


# Import the generator module from tools/
MODULE_PATH = Path(__file__).resolve().parents[2] / "tools" / "coverage_map.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))
import coverage_map as cm  # type: ignore[import-not-found]  # noqa: E402


def write_text(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def test_option_a_derivations_and_schema_version(tmp_path: Path, monkeypatch: Any):
    # Arrange: temporary repo structure with a single policy having placeholders/missing fields
    policies_root = tmp_path / "policies" / "gdpr" / "data_minimization"
    meta = (
        "id: gdpr.data_minimization\n"
        "name: <>\n"  # placeholder to trigger humanize_name
        "standard: <>\n"  # placeholder -> derive (GDPR, 2016/679)
        "version: n/a\n"
        "description: <>\n"  # placeholder will be replaced
        "path: policies/gdpr/data_minimization/policy.rego\n"
        "geo:\n"
        "  scope: EU\n"  # jurisdiction will be derived from geo.scope
    )
    write_text(policies_root / "metadata.yaml", meta)

    # Minimal compliance map referencing this policy to populate coverage labels
    maps_dir = tmp_path / "maps"
    cmap = (
        "regulation: TestReg\n"
        "version: '1.0'\n"
        "sections:\n"
        "  1.1:\n"
        "    title: Test Section\n"
        "    policies:\n"
        "      - gdpr.data_minimization\n"
    )
    write_text(maps_dir / "test.yml", cmap)

    # Redirect module constants to temp locations
    monkeypatch.setattr(cm, "POLICY_ROOT", tmp_path / "policies")
    monkeypatch.setattr(cm, "MAPS_DIR", maps_dir)
    # Output files redirected into tmp dist dir
    dist_dir = tmp_path / "dist"
    monkeypatch.setattr(cm, "OUT_INDEX_JSON", dist_dir / "policies-index.json")
    monkeypatch.setattr(cm, "OUT_PLUGIN_INDEX_JSON", dist_dir / "index.json")
    monkeypatch.setattr(cm, "OUT_COVERAGE_JSON", dist_dir / "coverage.json")
    monkeypatch.setattr(cm, "OUT_POLICIES_CSV", dist_dir / "policies.csv")

    # Ensure output directory exists
    dist_dir.mkdir(parents=True, exist_ok=True)

    # Act: load, generate, and read plugin index
    meta_idx = cm.load_metadata_index()
    maps = cm.load_mappings()
    cm.write_json_outputs(maps, meta_idx)

    data: Dict[str, Any] = json.loads((dist_dir / "index.json").read_text(encoding="utf-8"))

    # Assert: schemaVersion present (Option A keeps generator emitting enriched index)
    assert isinstance(data.get("schemaVersion"), int)
    pkgs: List[Dict[str, Any]] = list(data.get("packages") or [])
    assert len(pkgs) == 1
    pkg = pkgs[0]

    # Derived/sanitized fields
    assert pkg["id"] == "gdpr.data_minimization"
    # Name should be humanized from id (spaces + title-case for non-acronyms)
    assert pkg["name"] == "Data Minimization"
    assert pkg["standard"] == "GDPR"
    assert pkg["version"] == "2016/679"
    assert pkg["description"].startswith("Policy: Data Minimization")

    # Jurisdiction derived from geo.scope
    assert pkg.get("jurisdiction") == ["EU"]

    # Owner derived by domain mapping (gdpr -> compliance)
    assert pkg.get("owner") == "compliance"

    # Framework inferred from .rego path -> gatekeeper, tags derived accordingly
    assert pkg.get("framework") == "gatekeeper"
    tags = list(pkg.get("tags") or [])
    assert set(tags) >= {"gdpr", "gatekeeper", "rego"}

    # Coverage label rendered from test map
    cov = list(pkg.get("coverage") or [])
    assert any("TestReg 1.0 1.1" in str(c) for c in cov)

    # Repo pointers
    assert pkg.get("repoPath", "").endswith("policies/gdpr/data_minimization")
    assert pkg.get("repoUrl", "").endswith("policies/gdpr/data_minimization")
