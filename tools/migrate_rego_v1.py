#!/usr/bin/env python3
"""Migrate rulehub Rego policies to Rego v1 syntax.

Transforms in-place (idempotent):
  allow {        -> allow if {
  deny[msg] {    -> deny contains msg if {
  test_xxx {     -> test_xxx if {
Removes: 'import future.keywords.if' lines (no longer needed in v1).

Only processes .rego files under policies/ whose package starts with 'package rulehub.'
Provides --dry-run to preview changes.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
POLICIES = ROOT / "policies"

ALLOW_RE = re.compile(r'^(allow) \{')
DENY_INDEX_RE = re.compile(r'^(deny)\[msg\] \{')
TEST_RE = re.compile(r'^(test_[A-Za-z0-9_]+) \{')
IMPORT_IF_RE = re.compile(r'^import\s+future\.keywords\.if\s*$')
PACKAGE_RULEHUB_RE = re.compile(r'^package\s+rulehub\.')


def transform(lines: list[str]) -> tuple[list[str], bool]:
    changed = False
    out: list[str] = []
    for i, line in enumerate(lines):
        # Remove import future.keywords.if
        if IMPORT_IF_RE.match(line.strip()):
            changed = True
            continue
        # Only apply structural rule head changes (avoid touching comments)
        m_allow = ALLOW_RE.match(line)
        if m_allow:
            if ' if {' not in line:  # not already migrated
                line = line.replace('allow {', 'allow if {')
                changed = True
        m_deny = DENY_INDEX_RE.match(line)
        if m_deny:
            line = line.replace('deny[msg] {', 'deny contains msg if {')
            changed = True
        m_test = TEST_RE.match(line)
        if m_test:
            head = m_test.group(1)
            # Avoid double migration
            if not line.startswith(f"{head} if "):
                line = line.replace(f"{head} {{", f"{head} if {{")
                changed = True
        out.append(line)
    return out, changed


def migrate(dry_run: bool = False) -> int:
    edited = 0
    for path in POLICIES.rglob('*.rego'):
        try:
            text = path.read_text(encoding='utf-8').splitlines()
        except Exception as e:
            print(f"Skip {path}: {e}")
            continue
        if not any(PACKAGE_RULEHUB_RE.match(line) for line in text):
            continue
        new_lines, changed = transform(text)
        if changed:
            edited += 1
            rel = path.relative_to(ROOT)
            if dry_run:
                print(f"[DRY] Would migrate {rel}")
            else:
                path.write_text('\n'.join(new_lines) + '\n', encoding='utf-8')
                print(f"Migrated {rel}")
    print(f"Done. Files changed: {edited}")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()
    migrate(dry_run=args.dry_run)


if __name__ == '__main__':
    sys.exit(main())
