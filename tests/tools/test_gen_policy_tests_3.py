import subprocess
import sys
from pathlib import Path


def test_dry_run_creates_plan(tmp_path, monkeypatch):
    # create minimal policies tree
    pol_dir = tmp_path / "policies" / "demo" / "three_denies"
    pol_dir.mkdir(parents=True)
    pol = pol_dir / "policy.rego"
    pol.write_text('\n'.join([
        'package rulehub.demo.three_denies',
        '',
        'deny contains msg if {',
        '    not input.flag_a',
        '}',
        '',
        'deny contains msg if {',
        '    not input.flag_b',
        '}',
        '',
        'deny contains msg if {',
        '    not input.flag_c',
        '}',
    ]), encoding='utf-8')

    # run dry-run
    script = Path.cwd() / 'tools' / 'gen_policy_tests_3.py'
    proc = subprocess.run([
        sys.executable,
        str(script),
        '--policies-root',
        str(tmp_path / 'policies'),
    ], capture_output=True, text=True)
    assert proc.returncode == 0
    assert '(dry-run) Would write' in proc.stdout


def test_policy_flag_mismatch_exits_nonzero(tmp_path):
    pol_dir = tmp_path / "policies" / "demo" / "one_deny"
    pol_dir.mkdir(parents=True)
    pol = pol_dir / "policy.rego"
    pol.write_text('\n'.join([
        'package rulehub.demo.one_deny',
        '',
        'deny contains msg if {',
        '    not input.flag_a',
        '}',
    ]), encoding='utf-8')

    script = Path.cwd() / 'tools' / 'gen_policy_tests_3.py'
    # specify the policy path relative to policies root
    proc = subprocess.run([
        sys.executable,
        str(script),
        '--policies-root',
        str(tmp_path / 'policies'),
        '--policy',
        'demo/one_deny/policy.rego',
    ], capture_output=True, text=True)
    # should exit with code 3 as implemented for deny mismatch
    assert proc.returncode == 3
    assert 'has 1 deny rules (expected 3)' in proc.stdout
