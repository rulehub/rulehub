#!/usr/bin/env python3
"""Migrate single-string metadata 'path' fields to arrays including policy + test.

Rules:
 - Only process metadata.yaml under policies/**.
 - If 'path' is already an array -> leave unchanged.
 - If 'path' is a string pointing to a directory under policies/<domain>/<id_part> AND
   policy.rego + policy_test.rego both exist in that directory -> replace with array of both files.
 - If 'path' is a string pointing to an external addon template (addons/*) -> leave unchanged.
 - Dry-run by default; use --apply to modify files.

Outputs summary of changes and skipped reasons.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import yaml


POLICY_ROOT = Path('policies')


def load_metadata(meta_path: Path) -> dict:
    with open(meta_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def save_metadata(meta_path: Path, data: dict) -> None:
    with open(meta_path, 'w', encoding='utf-8') as f:
        yaml.safe_dump(data, f, sort_keys=False, width=1000)


def migrate(meta_path: Path) -> tuple[bool, str]:
    data = load_metadata(meta_path)
    pval = data.get('path')
    if pval is None:
        return False, 'no path field'
    # Already list
    if isinstance(pval, list):
        return False, 'already array'
    if not isinstance(pval, str):
        return False, 'unsupported path type'
    if pval.startswith('addons/'):
        return False, 'external addon template'
    # Expect directory style path: policies/<domain>/<policy_dir>
    dir_path = Path(pval)
    # If points directly to a file keep (could be rego or constraint)
    if dir_path.is_file():
        return False, 'already file path'
    # Derive expected policy directory
    policy_dir = dir_path
    policy_file = policy_dir / 'policy.rego'
    test_file = policy_dir / 'policy_test.rego'
    if not (policy_file.exists() and test_file.exists()):
        return False, 'missing policy or test file'
    data['path'] = [str(policy_file), str(test_file)]
    # write only if changed
    existing = load_metadata(meta_path)
    if existing.get('path') == data['path']:
        return False, 'already migrated'
    save_metadata(meta_path, data)
    return True, 'migrated'


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true',
                    help='Write changes (default dry-run)')
    args = ap.parse_args()

    metas = list(POLICY_ROOT.glob('**/metadata.yaml'))
    changed = 0
    for meta in metas:
        data = load_metadata(meta)
        pval = data.get('path')
        if isinstance(pval, list):
            continue
        # Re-run logic (duplicate) but only save when --apply
        if isinstance(pval, str) and not pval.startswith('addons/'):
            policy_dir = Path(pval)
            policy_file = policy_dir / 'policy.rego'
            test_file = policy_dir / 'policy_test.rego'
            if policy_file.exists() and test_file.exists():
                if args.apply:
                    new_path = [str(policy_file), str(test_file)]
                    if data.get('path') != new_path:
                        data['path'] = new_path
                        save_metadata(meta, data)
                        print(f"UPDATED {meta}")
                    else:
                        print(f"SKIP {meta}: already migrated")
                else:
                    print(f"DRY {meta}: would migrate")
                changed += 1
    print(f"Total {'migrated' if args.apply else 'candidates'}: {changed}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
