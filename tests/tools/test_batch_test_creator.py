import json
import sys
from pathlib import Path
import subprocess


def test_batch_dry_run(tmp_path):
    # Setup sample policies
    root = tmp_path / 'policies'
    p1 = root / 'demo' / 'pol1'
    p1.mkdir(parents=True)
    (p1 / 'policy.rego').write_text('\n'.join([
        'package rulehub.demo.pol1',
        '',
        'deny contains msg if {',
        '  not input.a',
        '}',
        '',
        'deny contains msg if {',
        '  not input.b',
        '}',
    ]), encoding='utf-8')

    script = Path.cwd() / 'tools' / 'batch_test_creator.py'
    proc = subprocess.run(
        [
            sys.executable,
            str(script),
            '--policies-root',
            str(root),
            '--dry-run',
        ],
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0
    assert '(dry-run) Would run:' in proc.stdout


def test_batch_apply_single_policy(tmp_path):
    # create a policy with exactly 2 deny rules and run generator via batch tool
    root = tmp_path / 'policies'
    p1 = root / 'demo' / 'pol1'
    p1.mkdir(parents=True)
    (p1 / 'policy.rego').write_text('\n'.join([
        'package rulehub.demo.pol1',
        '',
        'deny contains msg if {',
        '  not input.a',
        '}',
        '',
        'deny contains msg if {',
        '  not input.b',
        '}',
    ]), encoding='utf-8')

    script = Path.cwd() / 'tools' / 'batch_test_creator.py'
    proc = subprocess.run(
        [
            sys.executable,
            str(script),
            '--policies-root',
            str(root),
            '--policy',
            'demo/pol1/policy.rego',
            '--dry-run',
        ],
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0
    assert '(dry-run) Would run:' in proc.stdout
