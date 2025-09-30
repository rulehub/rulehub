import textwrap
from pathlib import Path
import subprocess
import sys


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def write_tmp_map(tmp: Path, content: str) -> Path:
    p = tmp / "map.yml"
    p.write_text(textwrap.dedent(content), encoding="utf-8")
    return p


def test_check_detects_duplicates(tmp_path: Path):
    repo = Path(__file__).resolve().parents[2]
    maps_dir = tmp_path / "compliance" / "maps"
    maps_dir.mkdir(parents=True)
    write_tmp_map(
        maps_dir,
        """
        regulation: X
        version: 1
        sections:
          A:
            title: Section A
            policies: [a.one, b.two]
          B:
            title: Section B
            policies: [b.two, c.three, a.one]
        """,
    )

    script = repo / "tools" / "fix_compliance_map_dupes.py"
    proc = run([sys.executable, str(script), "--check", "--dir", str(maps_dir)], cwd=tmp_path)
    assert proc.returncode == 1
    assert "Duplicate policies" in (proc.stdout + proc.stderr)


def test_fix_removes_duplicates_preserving_first(tmp_path: Path):
    repo = Path(__file__).resolve().parents[2]
    maps_dir = tmp_path / "compliance" / "maps"
    maps_dir.mkdir(parents=True)
    path = write_tmp_map(
        maps_dir,
        """
        regulation: X
        version: 1
        sections:
          A:
            title: Section A
            policies: [a.one, b.two, b.two]
          B:
            title: Section B
            policies: [b.two, c.three, a.one, a.one]
        """,
    )

    script = repo / "tools" / "fix_compliance_map_dupes.py"
    proc = run([sys.executable, str(script), "--fix", "--dir", str(maps_dir)], cwd=tmp_path)
    assert proc.returncode == 0
    out = path.read_text(encoding="utf-8")
    # first occurrences are kept globally; later duplicates removed
    assert out.count("a.one") == 1
    assert out.count("b.two") == 1
    assert "c.three" in out
