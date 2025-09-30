#!/usr/bin/env python3
"""Repair incorrect control flag transformations introduced by refactor_policies.

Issues produced patterns like:
    input.controls == false["domain.policy_id"]
Which is invalid Rego. Should be:
    input.controls["domain.policy_id"] == false

Also ensure any lingering 'not input.controls["id"]' become 'input.controls["id"] == false'.
"""
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent / "policies"

PAT_BAD = re.compile(r'(input\.controls) == false\["([^"]+)"\]')
PAT_NOT = re.compile(r'not (input\.controls\["[^"]+"\])')

changed_files = []
for f in ROOT.rglob('policy.rego'):
    text = f.read_text(encoding='utf-8')
    new = PAT_BAD.sub(lambda m: f'{m.group(1)}["{m.group(2)}"] == false', text)
    new = PAT_NOT.sub(lambda m: f'{m.group(1)} == false', new)
    if new != text:
        f.write_text(new, encoding='utf-8')
        changed_files.append(f)

print(f'Fixed {len(changed_files)} files')
for cf in changed_files[:10]:
    print('FIXED', cf)
