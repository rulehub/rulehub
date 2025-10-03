"""Normalize policy metadata YAML files:

Functions:
  1. Repair malformed list indentation for keys: path, links.
  2. Deduplicate links (preserve first occurrence order).
  3. Normalize certain URL patterns (eur-lex TXT/PDF -> TXT, decode %3A in CELEX query).
    4. Optionally (flag) add missing authoritative link from export file (links_export.json)
         if present there but not in metadata.
  5. Report vendor / non-authoritative domains (no automatic removal).

Usage:
  Dry run (default):
      python tools/normalize_links.py
  Apply changes:
      python tools/normalize_links.py --write
  Also sync export-only links into metadata:
      python tools/normalize_links.py --write --sync-export

The script intentionally performs minimal, surgical edits instead of full reserialization to avoid
unintended churn (e.g., key reordering). It patches lines in-place.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import List, Tuple


ROOT = os.path.join(os.path.dirname(__file__), '..', 'policies')
EXPORT_PATH = os.path.join(os.path.dirname(__file__), '..', 'links_export.json')

VENDOR_DOMAINS = [
    'sportradar.com',
    'emvco.com',
    'styra.com',
    'upguard.com',
]

CELEX_QUERY_RE = re.compile(
    r'(https://eur-lex.europa.eu/legal-content/[^\s]*?TXT/)(PDF/)?(\?uri=CELEX%3A|\?uri=CELEX:)([0-9A-Z]+)'
)


def load_export_links():
    if not os.path.isfile(EXPORT_PATH):
        return {}
    with open(EXPORT_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return {p['id']: p.get('links', []) for p in data.get('policies', [])}


def normalize_url(url: str, eli: bool = False) -> str:
    """Return a normalized URL.

    Current rules:
      * Collapse eur-lex TXT/PDF to TXT
      * Decode %3A -> : in CELEX query segment
      * Optional: convert certain eur-lex CELEX query forms to /eli/ canonical form when --eli flag passed
    """
    url = url.strip()
    # Collapse TXT/PDF/
    url = url.replace('TXT/PDF/', 'TXT/')
    # Decode colon encoding in CELEX param
    url = url.replace('%3A', ':')
    if eli:
        # Convert patterns like https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32018L0843
        m = re.search(
            r'https://eur-lex.europa.eu/legal-content/([A-Z]{2})/TXT/\?uri=CELEX:([0-9A-Z]+)',
            url,
        )
        if m:
            celex = m.group(2)
            # Heuristic: directives/regulations start with 3 (year) 20.. etc.
            # ELI canonical form: https://eur-lex.europa.eu/eli/<type>/<year>/<number>/oj
            # Simplified parse: CELEX 32018L0843 -> year 2018, inst L, number 843.
            if re.match(r'3\d{3}[A-Z]\d{4}', celex):
                year = celex[1:5]
                inst = celex[5]  # e.g. L (directive) R (regulation) etc.
                num = celex[6:].lstrip('0') or '0'
                type_map = {'R': 'reg', 'L': 'dir', 'D': 'dec'}
                t = type_map.get(inst)
                if t:
                    # Compose simplified eli path variant; if not parseable keep original.
                    candidate = f'https://eur-lex.europa.eu/eli/{t}/{year}/{num}/oj'
                    url = candidate
    return url


def repair_block(lines: List[str], key: str) -> Tuple[List[str], bool]:
    """Ensure list items for given key are properly indented under the key.

    Looks for pattern:
        key: [] (optional)
        - item
    and transforms to:
        key:
          - item
    Only touches contiguous list item region immediately following the key.
    """
    changed = False
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.match(rf'^{key}:\s*\[\]\s*$', line) or re.match(rf'^{key}:\s*$', line):
            # Confirm next lines are list items with leading '- '
            j = i + 1
            items_started = False
            block_changed = False
            while j < len(lines):
                nxt = lines[j]
                if not nxt.strip():
                    break
                if re.match(r'^[A-Za-z0-9_#]', nxt):
                    break  # next top-level key -> no items
                if re.match(r'^-\s+\S', nxt):
                    items_started = True
                    # indent it
                    lines[j] = '  ' + nxt
                    block_changed = True
                else:
                    # If already indented or different pattern stop
                    if re.match(r'^\s+-\s+\S', nxt):
                        items_started = True  # already indented
                    else:
                        break
                j += 1
            if items_started:
                if lines[i].endswith('[]'):
                    lines[i] = f'{key}:'
                    block_changed = True
                if block_changed:
                    changed = True
        i += 1
    return lines, changed


def extract_list(lines: List[str], key: str) -> Tuple[List[str], Tuple[int, int]]:
    """Extract list items (already assumed to be indented) for a key; returns items and span indices."""
    for idx, line in enumerate(lines):
        if re.match(rf'^{key}:\s*$', line):
            items = []
            j = idx + 1
            while j < len(lines):
                cur = lines[j]
                if not cur.strip():
                    break
                if re.match(r'^[A-Za-z0-9_#]', cur):
                    break
                m = re.match(r'^\s+-\s+(\S.*)$', cur)
                if m:
                    items.append(m.group(1).strip())
                else:
                    break
                j += 1
            return items, (idx + 1, j)
    return [], (-1, -1)


def dedupe_preserve(seq: List[str]) -> List[str]:
    seen = set()
    out = []
    for s in seq:
        if s not in seen:
            seen.add(s)
            out.append(s)
    return out


def process_file(path: str, export_links: dict, sync_export: bool, write: bool, eli: bool) -> dict:
    text = open(path, 'r', encoding='utf-8', errors='ignore').read().rstrip('\n')
    lines = text.split('\n')
    changed = False

    for key in ('path', 'links'):
        lines, c = repair_block(lines, key)
        changed = changed or c

    # Extract id
    m_id = re.search(r'^id:\s*([\w\.]+)', '\n'.join(lines), flags=re.MULTILINE)
    policy_id = m_id.group(1) if m_id else None

    # Extract and normalize links
    links_list, span = extract_list(lines, 'links')
    vendor_flags = []
    if links_list:
        norm_links = []
        for u in links_list:
            nu = normalize_url(u, eli=eli)
            norm_links.append(nu)
        norm_links = dedupe_preserve(norm_links)
        if export_links.get(policy_id) and sync_export:
            for u in export_links[policy_id]:
                nu = normalize_url(u, eli=eli)
                if nu not in norm_links:
                    norm_links.append(nu)
        # Replace block if changed
        if norm_links != links_list and span[0] != -1:
            new_block = [f'  - {u}' for u in norm_links]
            lines = lines[: span[0]] + new_block + lines[span[1] :]
            changed = True
        # Vendor detection
        for u in norm_links:
            for dom in VENDOR_DOMAINS:
                if dom in u:
                    vendor_flags.append(u)

    # If changed, write back
    new_text = '\n'.join(lines) + '\n'
    if write and changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)

    return {
        'path': path,
        'changed': changed and write,
        'would_change': changed and not write,
        'vendor_links': vendor_flags,
        'policy_id': policy_id,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--write', action='store_true', help='Apply changes (in-place).')
    ap.add_argument('--sync-export', action='store_true', help='Add links present only in links_export.json.')
    ap.add_argument('--eli', action='store_true', help='Attempt eur-lex CELEX -> /eli/ canonical conversion.')
    ap.add_argument('--check', action='store_true', help='Exit non-zero if any file would change (use in CI).')
    args = ap.parse_args()

    export_links = load_export_links()
    results = []
    for dirpath, _, files in os.walk(ROOT):
        if 'metadata.yaml' in files:
            p = os.path.join(dirpath, 'metadata.yaml')
            results.append(process_file(p, export_links, args.sync_export, args.write, args.eli))

    changed = [r for r in results if r['changed'] or r['would_change']]
    vendor = [(r['policy_id'], r['vendor_links']) for r in results if r['vendor_links']]

    print(f'Metadata files processed: {len(results)}')
    print(f'Files needing changes: {len(changed)} (write={args.write})')
    if vendor:
        print('Vendor / non-authoritative links detected:')
        for pid, links in vendor:
            for u in links:
                print(f'  {pid}: {u}')

    if not args.write:
        print('\nDry run complete. Re-run with --write to apply.')
    if args.check:
        # any file needing change triggers failure
        need = [r for r in results if r['would_change']]
        if need:
            print(f'--check: {len(need)} file(s) need normalization')
            sys.exit(2)
        print('--check: all normalized')


if __name__ == '__main__':
    main()
