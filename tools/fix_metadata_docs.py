#!/usr/bin/env python3
"""
Conservative metadata YAML fixer.
- Scans policies/**/metadata.yaml
- For each file, loads all YAML documents with PyYAML
- Chooses the last document that is a mapping and contains an 'id' key
- Rewrites the file as a single document with the project's schema comment header

This is conservative: it preserves data content but will lose comments. Use with --dry-run to preview.
"""
import argparse
import sys
from pathlib import Path

import yaml


SCHEMA_LINE = "# yaml-language-server: $schema=../../../tools/schemas/policy-metadata.schema.json"


def process_file(p: Path, apply: bool) -> int:
    text = p.read_text(encoding="utf-8")
    try:
        docs = list(yaml.safe_load_all(text))
    except Exception as e:
        print(f"SKIP {p}: parse error: {e}")
        return 1
    # find last mapping doc with 'id'
    chosen = None
    for d in docs:
        if isinstance(d, dict) and 'id' in d:
            chosen = d
    if chosen is None:
        # if only one doc and mapping, try it
        if len(docs) == 1 and isinstance(docs[0], dict):
            chosen = docs[0]
        else:
            print(
                f"SKIP {p}: no suitable mapping doc with 'id' found (docs={len(docs)})")
            return 1
    out = SCHEMA_LINE + "\n" + \
        yaml.safe_dump(chosen, sort_keys=False,
                       default_flow_style=False, width=140, indent=2)
    if not apply:
        print(f"DRY {p}: would rewrite (size {len(out)} bytes)")
        return 0
    # write back only if different
    existing = text
    # normalize existing by removing leading schema line(s) for comparison
    if existing.strip() == out.strip():
        print(f"SKIP {p}: already normalized")
        return 0
    p.write_text(out, encoding="utf-8")
    print(f"FIXED {p}")
    return 0


def find_policy_metadata(root: Path):
    return sorted(root.glob('policies/**/metadata.yaml'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true',
                    help='Actually rewrite files')
    ap.add_argument('--root', type=str, default='.', help='Repository root')
    args = ap.parse_args()
    root = Path(args.root)
    files = find_policy_metadata(root)
    if not files:
        print('No metadata.yaml files found under policies/')
        return 1
    failures = 0
    for f in files:
        rc = process_file(f, args.apply)
        failures += rc
    if failures:
        print(f"Completed with {failures} items skipped or errors")
        return 2
    print("Completed successfully")
    return 0


if __name__ == '__main__':
    sys.exit(main())
