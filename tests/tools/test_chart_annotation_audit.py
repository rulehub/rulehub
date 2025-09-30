import sys
from pathlib import Path
import yaml

import pytest

MODULE_PATH = Path(__file__).resolve(
).parents[2] / "tools" / "chart_annotation_audit.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))

import chart_annotation_audit as caa  # noqa: E402


def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


@pytest.fixture
def temp_repo(tmp_path, monkeypatch):
    # create minimal policies metadata and a charts dir
    policies_root = tmp_path / "policies" / "sample"
    policies_root.mkdir(parents=True)

    # metadata
    meta = {
        "id": "pci.test_policy",
        "name": "Test Policy",
        "links": ["https://example.com/pci"],
    }
    (policies_root / "metadata.yaml").write_text(yaml.safe_dump(meta), encoding="utf-8")

    charts_dir = tmp_path / "charts"
    charts_dir.mkdir()
    monkeypatch.chdir(tmp_path)
    return tmp_path


def test_happy_path_matches(temp_repo, capsys):
    charts_dir = temp_repo / "charts"
    # create a chart file with matching annotations
    content = """
apiVersion: v1
kind: ConfigMap
metadata:
  annotations:
    rulehub.id: pci.test_policy
    rulehub.title: "Test Policy"
    rulehub.links: |
      - https://example.com/pci
data: {}
"""
    (charts_dir / "cm.yaml").write_text(content, encoding="utf-8")

    rc = caa.main([
        "--charts-dir",
        str(charts_dir),
        "--policies-root",
        str(temp_repo / "policies"),
    ])
    out = capsys.readouterr()
    assert rc == 0
    assert "No divergences found" in out.out


def test_missing_charts_dir_errors(temp_repo, capsys):
    missing = temp_repo / "nocharts"
    rc = caa.main([
        "--charts-dir",
        str(missing),
        "--policies-root",
        str(temp_repo / "policies"),
    ])
    assert rc == 1


def test_divergence_report_written(temp_repo, capsys, tmp_path):
    charts_dir = temp_repo / "charts"
    # mismatching title and missing link
    content = """
apiVersion: v1
kind: ConfigMap
metadata:
  annotations:
    rulehub.id: pci.test_policy
    rulehub.title: "Wrong Title"
data: {}
"""
    (charts_dir / "cm.yaml").write_text(content, encoding="utf-8")
    out_file = tmp_path / "out.md"
    rc = caa.main([
        "--charts-dir",
        str(charts_dir),
        "--policies-root",
        str(temp_repo / "policies"),
        "--out",
        str(out_file),
    ])
    assert rc == 0
    text = out_file.read_text(encoding="utf-8")
    assert "rulehub.title" in text
    assert "rulehub.links" in text
