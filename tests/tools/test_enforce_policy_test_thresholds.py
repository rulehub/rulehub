import json
import os
import subprocess
import sys
from pathlib import Path

# Minimal tests for enforce_policy_test_thresholds.py


def write_cov(tmp: Path, dual_pct: float, multi_inadequate: int):
    data = {
        "tested": 1,
        "total": 1,
        "percent": 100.0,
        "dual_direction": {"count": 1 if dual_pct == 100 else 0, "percent": dual_pct},
        "multi_rule": {
            "policies_with_multi": 0,
            "adequate": 0,
            "count_inadequate": multi_inadequate,
            "list_inadequate": [],
        },
        "details": [],
    }
    (tmp / "dist").mkdir(exist_ok=True)
    (tmp / "dist" / "policy-test-coverage.json").write_text(json.dumps(data), encoding="utf-8")


def run(tmp: Path, env=None) -> int:
    """Run the enforcement script while using tmp as working dir (where dist/ lives).

    The script itself resides in the repo root under tools/; we call it via an
    absolute path so tests don't need a copied script inside tmp.
    """
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "tools" / "enforce_policy_test_thresholds.py"
    cmd = [sys.executable, str(script)]
    return subprocess.run(cmd, cwd=tmp, env=env).returncode


def test_ok(tmp_path: Path):
    write_cov(tmp_path, 100.0, 0)
    assert run(tmp_path) == 0


def test_fail_dual(tmp_path: Path):
    write_cov(tmp_path, 90.0, 0)
    assert run(tmp_path) == 2


def test_fail_multi(tmp_path: Path):
    write_cov(tmp_path, 100.0, 2)
    assert run(tmp_path) == 2


def test_allow_relax_env(tmp_path: Path):
    write_cov(tmp_path, 95.0, 1)
    env = os.environ.copy()
    env.update({"REQUIRED_DUAL_PCT": "90", "ALLOW_MULTI_INADEQUATE": "1"})
    assert run(tmp_path, env=env) == 0
