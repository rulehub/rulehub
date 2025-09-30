import json
from pathlib import Path
import subprocess
import sys


def test_coverage_enhancer_produces_outputs(tmp_path):
    # create policies
    root = tmp_path / "policies"
    p1 = root / "demo" / "pol1"
    p1.mkdir(parents=True)
    (p1 / "policy.rego").write_text('\n'.join([
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

    p2 = root / "demo" / "pol2"
    p2.mkdir(parents=True)
    (p2 / "policy.rego").write_text('\n'.join([
        'package rulehub.demo.pol2',
        '',
        'deny contains msg if {',
        '  not input.x',
        '}',
    ]), encoding='utf-8')

    # add an existing test assertion for p1 (1 assertion)
    (p1 / "policy_test.rego").write_text('\n'.join([
        'package rulehub.demo.pol1',
        '',
        't if {',
        '  count(deny) > 0 with input as {"a": false, "b": true}',
        '}',
    ]), encoding='utf-8')

    script = Path.cwd() / 'tools' / 'coverage_enhancer.py'
    out_dir = tmp_path / 'dist' / 'coverage'
    proc = subprocess.run([
        sys.executable,
        str(script),
        '--policies-root',
        str(root),
        '--out-dir',
        str(out_dir),
    ], capture_output=True, text=True)
    assert proc.returncode == 0

    md = out_dir / 'phase1_medtech.md'
    js = out_dir / 'phase1_medtech.json'
    assert md.exists()
    assert js.exists()

    data = json.loads(js.read_text(encoding='utf-8'))
    # find rows for pol1 and pol2
    # check counts
    found_pol1 = any(
        'pol1/policy.rego' in d['policy_path']
        and d['deny_rules'] == 2
        and d['deny_test_assertions'] == 1
        for d in data
    )
    found_pol2 = any(
        'pol2/policy.rego' in d['policy_path']
        and d['deny_rules'] == 1
        and d['deny_test_assertions'] == 0
        for d in data
    )
    assert found_pol1
    assert found_pol2
