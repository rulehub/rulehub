import sys
from pathlib import Path

import yaml
import textwrap

MODULE_PATH = Path(__file__).resolve().parents[2] / "tools" / "coverage_map.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))

import coverage_map as cm  # noqa: E402


def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def test_load_metadata_index_supports_nested_standard(tmp_path, monkeypatch):
    # Arrange policies with nested standard
    meta_dir = tmp_path / "policies" / "fintech" / "pci_mfa_required"
    meta_dir.mkdir(parents=True)
    yaml_content = textwrap.dedent(
        """
        id: fintech.pci_mfa_required
        name: PCI DSS — MFA Required
        standard:
          name: PCI DSS
          version: "4.0"
        path: []
        """
    ).strip()
    write_file(meta_dir / "metadata.yaml", yaml_content)

    # And a simple map referencing it
    maps_dir = tmp_path / "compliance" / "maps"
    maps_dir.mkdir(parents=True)
    write_file(
        maps_dir / "demo.yml",
        yaml.safe_dump(
            {
                "regulation": "Demo",
                "version": "0",
                "sections": {"General": {"title": "T", "policies": ["fintech.pci_mfa_required"]}},
            }
        ),
    )

    # Redirect module paths
    monkeypatch.setattr(cm, "POLICY_ROOT", tmp_path / "policies")
    monkeypatch.setattr(cm, "MAPS_DIR", tmp_path / "compliance" / "maps")

    idx = cm.load_metadata_index()
    assert idx["fintech.pci_mfa_required"]["standard"] == "PCI DSS"
    assert idx["fintech.pci_mfa_required"]["version"] == "4.0"
