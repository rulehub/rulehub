import sys
from pathlib import Path

import yaml

MODULE_PATH = Path(__file__).resolve().parents[2] / "tools" / "validate_compliance_maps.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))

import validate_compliance_maps as vcm  # noqa: E402


def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def test_unknown_policy_ids_fail(tmp_path, monkeypatch, capsys):
    # Arrange: one valid metadata id and a map referencing unknown id
    meta_dir = tmp_path / "policies" / "pci" / "storage_encryption"
    meta_dir.mkdir(parents=True)
    write_file(
        meta_dir / "metadata.yaml",
        """
id: pci.storage_encryption
name: Storage Encryption
standard: pci
version: "4.0"
path: []
        """.strip(),
    )

    maps_dir = tmp_path / "compliance" / "maps"
    maps_dir.mkdir(parents=True)
    write_file(
        maps_dir / "demo.yml",
        yaml.safe_dump(
            {
                "regulation": "Demo",
                "version": "0",
                "sections": {
                    "S1": {"title": "t", "policies": ["pci.storage_encryption", "pci.unknown_id"]}
                },
            }
        ),
    )

    # Redirect paths
    monkeypatch.setattr(vcm, "POLICY_ROOT", tmp_path / "policies")
    monkeypatch.setattr(vcm, "MAPS_DIR", tmp_path / "compliance" / "maps")

    rc = vcm.main()
    out = capsys.readouterr()
    assert rc == 1
    assert "Unknown policy id(s) referenced" in out.out


def test_map_ok_when_all_ids_known(tmp_path, monkeypatch, capsys):
    # Arrange: two metadata IDs and a map referencing both
    for sub in [
        ("pci", "storage_encryption"),
        ("pci", "network_encryption"),
    ]:
        meta_dir = tmp_path / "policies" / sub[0] / sub[1]
        meta_dir.mkdir(parents=True)
        write_file(
            meta_dir / "metadata.yaml",
            f"""
id: {sub[0]}.{sub[1]}
name: {sub[1].replace('_', ' ').title()}
standard: pci
version: "4.0"
path: []
            """.strip(),
        )

    maps_dir = tmp_path / "compliance" / "maps"
    maps_dir.mkdir(parents=True)
    write_file(
        maps_dir / "demo.yml",
        yaml.safe_dump(
            {
                "regulation": "Demo",
                "version": "0",
                "sections": {
                    "S1": {
                        "title": "t",
                        "policies": ["pci.storage_encryption", "pci.network_encryption"],
                    }
                },
            }
        ),
    )

    monkeypatch.setattr(vcm, "POLICY_ROOT", tmp_path / "policies")
    monkeypatch.setattr(vcm, "MAPS_DIR", tmp_path / "compliance" / "maps")

    rc = vcm.main()
    out = capsys.readouterr()
    assert rc == 0
    assert "All compliance maps are valid." in out.out
