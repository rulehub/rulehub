import sys
from pathlib import Path

import pytest

MODULE_PATH = Path(__file__).resolve().parents[2] / "tools" / "validate_metadata.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))

import validate_metadata as vm  # noqa: E402
import textwrap


def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


@pytest.fixture
def temp_policy_dir(tmp_path, monkeypatch):
    # Create a temporary policies tree with a metadata file
    policies_root = tmp_path / "policies" / "sample"
    policies_root.mkdir(parents=True)

    # Point the module's POLICY_ROOT to this temp directory
    monkeypatch.setattr(vm, "POLICY_ROOT", tmp_path / "policies")

    return tmp_path


def test_nested_standard_and_geo_validates(temp_policy_dir, monkeypatch, capsys):
        metadata_file = temp_policy_dir / "policies" / "sample" / "metadata.yaml"
        yaml_content = textwrap.dedent(
                """
                id: fintech.pci_mfa_required
                name: PCI DSS — MFA Required
                standard:
                    name: PCI DSS
                    version: "4.0"
                geo:
                    regions: [Global]
                    countries: ["*"]
                    scope: Global
                path: []
                """
        ).strip()
        write_file(metadata_file, yaml_content)

        # Run from the temp repo root so relative paths resolve
        monkeypatch.chdir(temp_policy_dir)

        # Disable strict empty paths for this test
        monkeypatch.delenv("STRICT_EMPTY_PATHS", raising=False)

        rc = vm.main()
        out = capsys.readouterr()
        # Should pass schema; warn about empty path but not error
        assert rc == 0
        assert "All metadata files are valid." in out.out
