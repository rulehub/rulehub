import sys
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[2] / "tools" / "coverage_map.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))
import coverage_map as cm  # noqa: E402


def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def test_load_metadata_index_id_derivation_and_normalization(tmp_path, monkeypatch):
    # Policy A: explicit id, path as string, jurisdiction present
    p_a = tmp_path / "policies" / "gdpr" / "data_minimization"
    meta_a = (
        "id: gdpr.data_minimization\n"
        "name: Data Minimization\n"
        "standard: GDPR\n"
        "version: '2016'\n"
        "path: policies/gdpr/data_minimization/policy.rego\n"
        "jurisdiction: [EU, Global]\n"
    )
    write_file(p_a / "metadata.yaml", meta_a)

    # Policy B: missing id -> derive from folder names policies/<domain>/<folder>
    p_b = tmp_path / "policies" / "aml" / "suspicious_activity"
    meta_b = (
        "name: Suspicious Activity Monitoring\n"
        "standard:\n"
        "  name: EU AMLD\n"
        "  version: '5'\n"
        "path:\n"
        "  - policies/aml/suspicious_activity/policy.rego\n"
        "  - policies/aml/suspicious_activity/extra.rego\n"
    )
    write_file(p_b / "metadata.yaml", meta_b)

    # Point module constants to temp repo
    monkeypatch.setattr(cm, "POLICY_ROOT", tmp_path / "policies")

    idx = cm.load_metadata_index()

    # Assertions for Policy A
    a = idx["gdpr.data_minimization"]
    assert a["path"] == ["policies/gdpr/data_minimization/policy.rego"]
    assert a["standard"] == "GDPR"
    assert a["version"] == "2016"
    assert a["jurisdiction"] == ["EU", "Global"]

    # Assertions for Policy B (derived id)
    b = idx["aml.suspicious_activity"]
    assert sorted(b["path"]) == [
        "policies/aml/suspicious_activity/extra.rego",
        "policies/aml/suspicious_activity/policy.rego",
    ]
    assert b["standard"] == "EU AMLD"
    assert b["version"] == "5"

    # Ensure expected keys present
    expected_keys = {
        "name",
        "standard",
        "version",
        "path",
        "description",
        "framework",
        "severity",
        "owner",
        "tags",
        "links",
        "geo",
        "jurisdiction",
    }
    assert expected_keys.issubset(a.keys())
    assert expected_keys.issubset(b.keys())
