import json
import sys
from pathlib import Path

# ensure repo root is discoverable for imports when tests run
sys.path.insert(0, str(Path(".").resolve()))


def test_readiness_writes_tmp(tmp_path):
    root = Path(".").resolve()
    out_dir = tmp_path / "dist" / "release"
    out_dir.mkdir(parents=True)

    # run module as script
    from tools.release.readiness_report import main

    rc = main(["--root", str(root), "--out-dir", str(out_dir)])
    assert rc == 0
    md = out_dir / "readiness.md"
    js = out_dir / "readiness.json"
    assert md.exists()
    assert js.exists()
    data = json.loads(js.read_text())
    assert "git" in data


def test_readiness_handles_missing_changelog(tmp_path, monkeypatch):
    # create an empty temporary repo-like dir without CHANGELOG
    repo = tmp_path / "repo"
    repo.mkdir()
    (repo / "policies").mkdir()
    out = tmp_path / "out"
    out.mkdir()

    from tools.release.readiness_report import main

    rc = main(["--root", str(repo), "--out-dir", str(out)])
    assert rc == 0
    assert (out / "readiness.json").exists()
