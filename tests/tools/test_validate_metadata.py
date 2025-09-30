import os
import sys
from pathlib import Path

import pytest

# Import the module under test
MODULE_PATH = Path(__file__).resolve(
).parents[2] / "tools" / "validate_metadata.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))

import validate_metadata as vm  # noqa: E402


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


def test_validate_metadata_happy_path(temp_policy_dir, monkeypatch, capsys):
    # Happy path: valid schema and existing file path
    policy_file = temp_policy_dir / "policies" / "sample" / "rule.yaml"
    write_file(policy_file, "apiVersion: v1\nkind: ConfigMap\n")

    metadata_file = temp_policy_dir / "policies" / "sample" / "metadata.yaml"
    write_file(
        metadata_file,
        """
id: pci.storage_encryption
name: Storage Encryption
standard: pci
version: "1.0"
path: policies/sample/rule.yaml
geo:
    regions: ["global"]
    countries: ["*"]
    scope: global
        """.strip()
    )

    # Run from the temp repo root so relative paths resolve
    monkeypatch.chdir(temp_policy_dir)

    # Ensure STRICT_EMPTY_PATHS not forcing errors
    monkeypatch.delenv("STRICT_EMPTY_PATHS", raising=False)

    rc = vm.main()
    out = capsys.readouterr()
    assert rc == 0
    assert "All metadata files are valid." in out.out


def test_validate_metadata_edge_missing_path_file(temp_policy_dir, monkeypatch, capsys):
    # Edge: path points to a non-existent file; should error and return non-zero
    metadata_file = temp_policy_dir / "policies" / "sample" / "metadata.yaml"
    write_file(
        metadata_file,
        """
id: pci.storage_encryption
name: Storage Encryption
standard: pci
version: "1.0"
path: policies/sample/missing.yaml
        """.strip()
    )

    # Run from the temp repo root so relative paths resolve
    monkeypatch.chdir(temp_policy_dir)

    rc = vm.main()
    out = capsys.readouterr()
    assert rc == 1
    assert "Path not found" in out.out


def test_validate_metadata_strict_empty_paths(temp_policy_dir, monkeypatch, capsys):
        # Edge: empty path array with STRICT_EMPTY_PATHS=1 should fail
        metadata_file = temp_policy_dir / "policies" / "sample" / "metadata.yaml"
        write_file(
                metadata_file,
                """
id: gdpr.data_minimization
name: Data Minimization
standard:
    name: GDPR
    version: "2016"
path: []
                """.strip(),
        )
        monkeypatch.setenv("STRICT_EMPTY_PATHS", "1")
        monkeypatch.chdir(temp_policy_dir)
        rc = vm.main()
        out = capsys.readouterr()
        assert rc == 1
        assert "Warning: Empty path list" in out.out


def test_validate_metadata_nested_standard_success(temp_policy_dir, monkeypatch, capsys):
        # Nested standard form {name, version} and existing file path
        policy_file = temp_policy_dir / "policies" / "sample" / "rule.yaml"
        write_file(policy_file, "apiVersion: v1\nkind: ConfigMap\n")

        metadata_file = temp_policy_dir / "policies" / "sample" / "metadata.yaml"
        write_file(
                metadata_file,
                """
id: aml.sanctions_screening
name: Sanctions screening
standard:
    name: EU AMLD
    version: "5"
path: policies/sample/rule.yaml
geo:
    regions: ["eu"]
    countries: ["*"]
    scope: regional
                """.strip(),
        )
        monkeypatch.delenv("STRICT_EMPTY_PATHS", raising=False)
        monkeypatch.chdir(temp_policy_dir)
        rc = vm.main()
        out = capsys.readouterr()
        assert rc == 0
        assert "All metadata files are valid." in out.out


def test_duplicate_policy_ids_fail(temp_policy_dir, monkeypatch, capsys):
    # Arrange two metadata files with the same id
    d1 = temp_policy_dir / "policies" / "pci" / "storage_encryption"
    d2 = temp_policy_dir / "policies" / "pci" / "storage_encryption_dup"
    d1.mkdir(parents=True, exist_ok=True)
    d2.mkdir(parents=True, exist_ok=True)
    (d1 / "metadata.yaml").write_text(
        (
            "id: pci.storage_encryption\nname: A\nstandard: pci\nversion: '4.0'\npath: []\n"
        ),
        encoding="utf-8",
    )
    (d2 / "metadata.yaml").write_text(
        (
            "id: pci.storage_encryption\nname: B\nstandard: pci\nversion: '4.0'\npath: []\n"
        ),
        encoding="utf-8",
    )
    monkeypatch.chdir(temp_policy_dir)
    rc = vm.main()
    out = capsys.readouterr()
    assert rc == 1
    assert "Duplicate policy id 'pci.storage_encryption'" in out.out
