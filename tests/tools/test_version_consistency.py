from tools import version_consistency as vc
import tempfile
import os
import sys
from pathlib import Path

# ensure repo root is on sys.path so 'tools' package imports work during tests
ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def test_bump_version_patch():
    assert vc.bump_version("1.2.3", "patch") == "1.2.4"


def test_bump_version_minor():
    assert vc.bump_version("1.2.3", "minor") == "1.3.0"


def test_bump_version_major():
    assert vc.bump_version("1.2.3", "major") == "2.0.0"


def test_recommend_bump_level_major():
    msgs = ["fix: something", "feat: add X", "refactor!: breaking change"]
    assert vc.recommend_bump_level(msgs) == "major"


def test_recommend_bump_level_minor():
    msgs = ["fix: small", "feat: add Y"]
    assert vc.recommend_bump_level(msgs) == "minor"


def test_recommend_bump_level_patch():
    msgs = ["fix: small", "docs: update"]
    assert vc.recommend_bump_level(msgs) == "patch"


def test_extract_versions_temp_files(tmp_path):
    # create a fake package.json
    pj = tmp_path / "package.json"
    pj.write_text('{"name":"x","version":"2.3.4"}', encoding="utf-8")
    ch = tmp_path / "Chart.yaml"
    ch.write_text("version: 2.3.4\nappVersion: '2.3.4'\n", encoding="utf-8")

    inputs = [("package.json", str(pj)), ("Chart.yaml", str(ch))]
    res = vc.extract_versions(inputs)
    d = {r.source: r.version for r in res}
    assert d["package.json"] == "2.3.4"
    assert d["Chart.yaml"] == "2.3.4"


def test_main_force_version(tmp_path, capsys):
    # run main with force version and a temporary commit file
    commits = tmp_path / "commits.txt"
    commits.write_text("fix: a\n", encoding="utf-8")
    rc = vc.main(["--force-version", "9.9.9", "--commits-file", str(commits)])
    assert rc == 0
    captured = capsys.readouterr()
    assert "Recommended next version" in captured.out or "9.9.9" in captured.out
