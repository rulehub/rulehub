import json
from pathlib import Path
import subprocess
import sys
import tempfile


def run_script(cwd: Path, args=None):
    args = args or []
    cmd = [sys.executable, str(
        Path.cwd() / "tools" / "dependency_freshness.py")] + args
    # run with cwd set to repo root (test will set cwd via subprocess)
    res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return res


def test_offline_mode_creates_outputs(tmp_path: Path):
    # Create minimal package.json and requirements.txt
    pkg = tmp_path / "package.json"
    pkg.write_text('{"dependencies": {"left-pad": "1.0.0"}}', encoding="utf-8")
    req = tmp_path / "requirements.txt"
    req.write_text("requests==2.25.1\n", encoding="utf-8")

    # Run the script in offline mode
    res = run_script(tmp_path, args=["--offline"])
    assert res.returncode == 0, f"script failed: {res.stdout}\n{res.stderr}"

    out_dir = tmp_path / "dist" / "release"
    md = out_dir / "deps.md"
    js = out_dir / "deps.json"
    assert md.exists(), f"Missing {md}"
    assert js.exists(), f"Missing {js}"

    content = md.read_text(encoding="utf-8")
    assert "left-pad" in content
    # offline mode should mark latest as N/A
    assert "N/A" in content

    data = json.loads(js.read_text(encoding="utf-8"))
    assert "summary" in data
    assert data["summary"]["unknown"] >= 1
