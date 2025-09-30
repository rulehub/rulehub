import tempfile
from pathlib import Path
import importlib.util
import sys


def load_changelog_polish():
    repo_root = Path(__file__).resolve().parents[2]
    mod_path = repo_root / "tools" / "changelog_polish.py"
    spec = importlib.util.spec_from_file_location(
        "changelog_polish", str(mod_path))
    module = importlib.util.module_from_spec(spec)
    sys.modules["changelog_polish"] = module
    spec.loader.exec_module(module)
    return module


changelog_polish = load_changelog_polish()


def test_polish_happy(tmp_path: Path):
    changelog = tmp_path / "CHANGELOG.md"
    changelog.write_text(
        """
# Changelog

## [Unreleased]

### Added
- New feature A
- New feature B

### Fixed
- Bugfix 1

## [1.0.0] - 2025-01-01
- initial
"""
    )

    out = tmp_path / "dist/release/changelog_polished.md"
    rc = changelog_polish.main(
        ["--changelog", str(changelog), "--out", str(out)])
    assert rc == 0
    assert out.exists()
    txt = out.read_text()
    assert "Polished Unreleased Changelog" in txt
    assert "Added" in txt
    assert "Fixed" in txt


def test_polish_no_unreleased(tmp_path: Path):
    changelog = tmp_path / "CHANGELOG.md"
    changelog.write_text(
        """
# Changelog

## [1.0.0] - 2025-01-01
- initial
"""
    )

    out = tmp_path / "dist/release/changelog_polished.md"
    rc = changelog_polish.main(
        ["--changelog", str(changelog), "--out", str(out)])
    assert rc == 0
    assert out.exists()
    txt = out.read_text()
    assert "No unreleased changes found" in txt or "No unreleased changes" in txt
