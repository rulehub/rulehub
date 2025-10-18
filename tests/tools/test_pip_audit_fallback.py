import os
import subprocess
from pathlib import Path
from typing import Dict, List
import shutil
import pytest  # type: ignore

# This test exercises the fallback path in .github/scripts/pip-audit-run.sh
# Strategy: create a temporary directory with minimal requirements files, invoke the script
# with PIP_AUDIT_COMBINE=1 but purposely cause the combined run to fail by inserting an
# invalid requirement line only in the dev file; ensure legacy fallback still produces
# pip-audit-combined.json with zero vulns shape and exit code 0.
# We avoid network variability by relying on a non-existent package name that causes
# pip-audit resolution failure for the combined run, triggering fallback where each
# file separately is still resolvable (base ok, dev fails but tolerated by || true).

SCRIPT = Path(__file__).resolve().parents[2] / ".github" / "scripts" / "pip-audit-run.sh"


def run(cmd: List[str], cwd: Path, env: Dict[str, str]) -> subprocess.CompletedProcess[str]:  # type: ignore[type-arg]
    # mypy in repo may not have precise CompletedProcess generic enabled; ignore if flagged
    return subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True)  # type: ignore[no-any-return]


def test_pip_audit_combined_fallback(tmp_path: Path):  # type: ignore[no-untyped-def]
    if shutil.which("pip-audit") is None:
        pytest.skip("pip-audit not installed in test environment")
    base = tmp_path / "requirements.txt"
    dev = tmp_path / "requirements-dev.txt"
    # Use a trivial dependency that should resolve quickly.
    base.write_text("pyyaml==6.0.2\n")
    # Add an invalid requirement that will break combined resolution (unknown extra)
    dev.write_text("pyyaml==6.0.2[nonexistent-extra]\n")

    env = os.environ.copy()
    env.update({
        "PIP_AUDIT_COMBINE": "1",
        # Force ACT to synthetic SARIF, avoiding network for sarif second run
        "ACT": "true",
        # Avoid user/site interference
        "PYTHONNOUSERSITE": "1",
    })

    # Copy script locally so relative path operations remain stable
    script_target = tmp_path / "pip-audit-run.sh"
    script_target.write_text(SCRIPT.read_text())
    script_target.chmod(0o755)

    proc = run(["bash", str(script_target)], cwd=tmp_path, env=env)

    # The script should succeed (exit 0) because high vulns == 0 even though combined failed
    assert proc.returncode == 0, proc.stderr
    out = proc.stdout + proc.stderr
    # Confirm fallback message present
    assert "Combined run failed" in out or "combined run failed" in out.lower()

    combined_json = tmp_path / "pip-audit-combined.json"
    assert combined_json.exists()
    data = combined_json.read_text()
    # Should parse vulns key (even empty). Avoid importing json to keep simple & no network (stdlib ok though)
    import json  # noqa: WPS433

    parsed = json.loads(data)
    assert "vulns" in parsed
    assert isinstance(parsed["vulns"], list)

    # Ensure summary line printed
    assert "pip-audit: total=" in out
