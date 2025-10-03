#!/usr/bin/env python3
"""Check for missing policy translations.

Scans base English metadata under policies/**/metadata.yaml and compares against translation
files present under translations/<lang>/ matching <policy_id>.yaml.

Outputs a report to stdout listing per language:
- missing: policy IDs lacking a translation file
- stale: translation files whose source_hash (if present) mismatches the current SHA256 of the base description
- extra: translation files that have no corresponding base policy metadata

Exit codes:
0 -> no missing or stale translations
1 -> missing or stale translations detected (can be overridden via env ALLOW_STALE_TRANSLATIONS=1)

Environment variables:
  LANGS: comma-separated list of languages to check (default: all subdirectories of translations/ excluding 'en')
  FAIL_ON_EXTRA: if set to 1, treat extra translation files as failure (default 0)
  ALLOW_STALE_TRANSLATIONS: if set to 1, do not fail when stale are detected.

The script calculates the canonical description hash using SHA256 of the base English description string (UTF-8).
If a translation yaml file includes `source_hash` and it differs, it's considered stale.
If it omits source_hash, it's considered unknown (reported separately) unless the file only contains id field.

"""

from __future__ import annotations

import hashlib
import os
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

import yaml


REPO_ROOT = Path(__file__).resolve().parent.parent  # /workspaces/rulehub
POLICIES_DIR = REPO_ROOT / "policies"
TRANSLATIONS_DIR = REPO_ROOT / "translations"


def iter_metadata() -> List[Tuple[str, Path, dict]]:
    items: List[Tuple[str, Path, dict]] = []
    for path in POLICIES_DIR.rglob("metadata.yaml"):
        try:
            data = yaml.safe_load(path.read_text(encoding='utf-8')) or {}
        except Exception as e:
            print(f"ERROR: failed to parse {path}: {e}", file=sys.stderr)
            continue
        policy_id = data.get('id')
        if not policy_id:
            continue
        items.append((policy_id, path, data))
    return items


def sha256_text(s: str) -> str:
    return hashlib.sha256(s.encode('utf-8')).hexdigest()


def load_translation(policy_id: str, lang_dir: Path) -> Tuple[dict | None, Path]:
    path = lang_dir / f"{policy_id}.yaml"
    if not path.is_file():
        return None, path
    try:
        data = yaml.safe_load(path.read_text(encoding='utf-8')) or {}
    except Exception as e:
        print(f"ERROR: failed to parse translation {path}: {e}", file=sys.stderr)
        data = {}
    return data, path


def main() -> int:
    if not POLICIES_DIR.is_dir():
        print(f"No policies directory found at {POLICIES_DIR}", file=sys.stderr)
        return 2
    if not TRANSLATIONS_DIR.is_dir():
        print(f"No translations directory found at {TRANSLATIONS_DIR}", file=sys.stderr)
        return 2

    base_metadata = iter_metadata()
    base_index: Dict[str, dict] = {pid: data for pid, _p, data in base_metadata}

    # Determine languages
    if os.environ.get('LANGS'):
        langs = [lang_code.strip() for lang_code in os.environ['LANGS'].split(',') if lang_code.strip()]
    else:
        langs = [p.name for p in TRANSLATIONS_DIR.iterdir() if p.is_dir() and p.name != 'en']
    langs = sorted(set(langs))
    if not langs:
        print("No target languages to check (nothing to do)")
        return 0

    fail_on_extra = os.environ.get('FAIL_ON_EXTRA') == '1'
    allow_stale = os.environ.get('ALLOW_STALE_TRANSLATIONS') == '1'

    # Pre-compute description hashes
    desc_hash: Dict[str, str] = {}
    for pid, _p, data in base_metadata:
        desc = data.get('description', '') or ''
        desc_hash[pid] = sha256_text(desc)

    overall_missing: Dict[str, List[str]] = {}
    overall_stale: Dict[str, List[str]] = {}
    overall_unknown: Dict[str, List[str]] = {}
    overall_extra: Dict[str, List[str]] = {}

    for lang in langs:
        lang_dir = TRANSLATIONS_DIR / lang
        if not lang_dir.is_dir():
            print(f"WARN: language directory missing: {lang_dir}")
            continue

        missing: List[str] = []
        stale: List[str] = []
        unknown: List[str] = []

        # Build set of existing translation file IDs
        existing_ids: Set[str] = set()
        for f in lang_dir.glob("*.yaml"):
            existing_ids.add(f.stem)

        # Check each base policy
        for pid in base_index.keys():
            data, _path = load_translation(pid, lang_dir)
            if data is None:
                missing.append(pid)
                continue
            # Validate id alignment
            if data.get('id') and data['id'] != pid:
                print(
                    f"ERROR: translation id mismatch in {lang}/{pid}.yaml: {data.get('id')} != {pid}",
                    file=sys.stderr,
                )
            src_hash = data.get('source_hash')
            keys = set(data.keys()) - {'id'}
            if not src_hash and not keys:
                # Only id field present -> treat as missing
                missing.append(pid)
            elif not src_hash:
                # Some additional keys but no source hash -> unknown
                unknown.append(pid)
            elif src_hash != desc_hash[pid]:
                stale.append(pid)

        # Extra files (no base metadata)
        extra = sorted(existing_ids - base_index.keys())

        overall_missing[lang] = sorted(missing)
        overall_stale[lang] = sorted(stale)
        if unknown:
            overall_unknown[lang] = sorted(unknown)
        if extra:
            overall_extra[lang] = list(extra)

    # Reporting
    def print_section(title: str):
        print("\n== " + title + " ==")

    for lang in langs:
        print_section(f"Language: {lang}")
        print(f"Missing ({len(overall_missing.get(lang, []))}):")
        for pid in overall_missing.get(lang, []):
            print(f"  - {pid}")
        print(f"Stale ({len(overall_stale.get(lang, []))}):")
        for pid in overall_stale.get(lang, []):
            print(f"  - {pid}")
        if lang in overall_unknown:
            print(f"Unknown (no source_hash, partial) ({len(overall_unknown.get(lang, []))}):")
            for pid in overall_unknown.get(lang, []):
                print(f"  - {pid}")
        if lang in overall_extra:
            print(f"Extra ({len(overall_extra.get(lang, []))}):")
            for pid in overall_extra.get(lang, []):
                print(f"  - {pid}")

    failed = (
        any(overall_missing.values()) or any(overall_stale.values()) or (fail_on_extra and any(overall_extra.values()))
    )
    if failed:
        if allow_stale and not any(overall_missing.values()) and not (fail_on_extra and any(overall_extra.values())):
            return 0
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
