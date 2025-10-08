from pathlib import Path

from tools.export_plugin_metadata import build_packages


def write_yaml(p: Path, content: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")


def test_build_packages_minimal(tmp_path: Path):
    # Arrange: minimal policy metadata + compliance map referencing it
    meta = """
id: pci.storage_encryption
name: Storage encryption
standard:
  name: PCI DSS
  version: "4.0"
jurisdiction:
  - Global
"""
    map_yaml = """
regulation: PCI DSS
version: "4.0"
sections:
  1.1:
    title: Test Section
    policies:
      - pci.storage_encryption
"""
    meta_p = tmp_path / "policies/fintech/storage_encryption/metadata.yaml"
    map_p = tmp_path / "compliance/maps/pci.yml"
    write_yaml(meta_p, meta)
    write_yaml(map_p, map_yaml)

    # Act
    data = build_packages(policies_root=tmp_path / "policies", maps_root=tmp_path / "compliance/maps")

    # Assert
    assert "packages" in data
    pkgs = data["packages"]
    assert isinstance(pkgs, list) and len(pkgs) == 1
    pkg = pkgs[0]
    assert pkg["id"] == "pci.storage_encryption"
    assert pkg["name"] == "Storage encryption"
    assert pkg["standard"] == "PCI DSS"
    assert pkg["version"] == "4.0"
    assert pkg["jurisdiction"] == ["Global"]
    assert pkg["coverage"] == ["PCI DSS 4.0"]
