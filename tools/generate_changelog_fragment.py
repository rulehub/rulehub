#!/usr/bin/env python3
"""Generate a Markdown CHANGELOG fragment from git history.

Usage (examples):
  python tools/generate_changelog_fragment.py --base-tag v0.1.0 --target main --version 0.2.0
  python tools/generate_changelog_fragment.py --base-tag v0.1.0 --target feature/branch

SemVer version (for the heading) can be supplied via --version. If omitted a
placeholder <X.Y.Z> is used so the maintainer can edit manually.

Classification heuristics (commit subject, case-insensitive):
  Added:   ^(feat|add|new)\b, or commits that introduce new policy.rego files
  Fixed:   ^(fix|bug|hotfix)\b
  Changed: ^(refactor|perf|chore|change|rename|docs)\b, or modifications to existing policy.rego or compliance map files

Outputs sections: Added / Changed / Fixed (omits empty sections if
--no-empty-headings is passed). Always prints a heading suitable for direct
insertion above the previous release block.

Environment safety: pure read-only git commands; no repository mutations.

Exit codes:
  0 success
  2 invalid arguments / tag not found
  3 git command failure
"""

from __future__ import annotations

import argparse
import datetime as _dt
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, List, Set, Tuple


GIT = "git"


def run_git(args: List[str]) -> str:
    try:
        out = subprocess.check_output([GIT] + args, text=True)
        return out.strip("\n")
    except subprocess.CalledProcessError as e:
        print(f"[error] git {' '.join(args)} failed: {e}", file=sys.stderr)
        sys.exit(3)


def tag_exists(tag: str) -> bool:
    tags = run_git(["tag", "--list", tag])
    return bool(tags.strip())


ADD_PAT = re.compile(r"^(feat|add|new)\b", re.IGNORECASE)
FIX_PAT = re.compile(r"^(fix|bug|hotfix)\b", re.IGNORECASE)
CHG_PAT = re.compile(r"^(refactor|perf|chore|change|rename|docs)\b", re.IGNORECASE)


@dataclass
class Classifier:
    added: List[str] = field(default_factory=list)
    changed: List[str] = field(default_factory=list)
    fixed: List[str] = field(default_factory=list)

    def classify_commit(self, subject: str):
        s = subject.strip()
        if not s:
            return
        if ADD_PAT.search(s):
            self.added.append(s)
        elif FIX_PAT.search(s):
            self.fixed.append(s)
        elif CHG_PAT.search(s):
            self.changed.append(s)


def list_commits(base: str, target: str) -> List[str]:
    log = run_git(["log", "--no-merges", "--pretty=%s", f"{base}..{target}"])
    if not log:
        return []
    return [line for line in log.splitlines() if line.strip()]


def diff_name_status(base: str, target: str) -> List[Tuple[str, str]]:
    diff = run_git(["diff", "--name-status", f"{base}..{target}"])
    rows: List[Tuple[str, str]] = []
    for line in diff.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            rows.append((parts[0], parts[-1]))  # status, path
    return rows


MAP_LINE_ADDED = re.compile(r"^\+\s*-\s+([a-z0-9_.]+)\s*$")
MAP_LINE_REMOVED = re.compile(r"^-\s*-\s+([a-z0-9_.]+)\s*$")


def map_policy_changes(base: str, target: str, changed_files: Iterable[str]):
    summary = {}
    for path in changed_files:
        if not path.startswith("compliance/maps/") or not path.endswith(".yml"):
            continue
        # Obtain raw diff for this file
        diff_text = run_git(["diff", f"{base}..{target}", "--", path])
        added: Set[str] = set()
        removed: Set[str] = set()
        for line in diff_text.splitlines():
            if line.startswith("+++") or line.startswith("---"):
                continue
            m_add = MAP_LINE_ADDED.match(line)
            if m_add:
                added.add(m_add.group(1))
                continue
            m_rem = MAP_LINE_REMOVED.match(line)
            if m_rem:
                removed.add(m_rem.group(1))
        if added or removed:
            summary[path] = {"added": sorted(added), "removed": sorted(removed)}
    return summary


def detect_policy_file_changes(ns_rows: List[Tuple[str, str]]):
    added: List[str] = []
    modified: List[str] = []
    for status, path in ns_rows:
        if not path.endswith("/policy.rego"):
            continue
        if path.startswith("policies/"):
            if status == "A":
                added.append(path)
            elif status in {"M", "R", "C"}:  # modified / renamed / copied treated as changed
                modified.append(path)
    return sorted(added), sorted(modified)


def build_markdown(
    version: str | None,
    date: str,
    classifier: Classifier,
    new_policies: List[str],
    changed_policies: List[str],
    map_changes,
) -> str:
    heading_version = version if version else "<X.Y.Z>"
    md: List[str] = []
    md.append(f"## [{heading_version}] - {date}")
    # Aggregate Added section (new policies & commit subjects)
    added_section: List[str] = []
    if new_policies:
        added_section.append("New policies:")
        added_section.extend([f"  - {Path(p).parent.name}" for p in new_policies])
    if classifier.added:
        for subj in classifier.added:
            added_section.append(f"- {subj}")
    changed_section: List[str] = []
    if changed_policies:
        changed_section.append("Modified policies:")
        changed_section.extend([f"  - {Path(p).parent.name}" for p in changed_policies])
    if map_changes:
        for mpath, chg in sorted(map_changes.items()):
            adds = chg["added"]
            rems = chg["removed"]
            parts = []
            if adds:
                parts.append(f"Added {len(adds)}")
            if rems:
                parts.append(f"Removed {len(rems)}")
            if parts:
                changed_section.append(f"Map {Path(mpath).name}: {'; '.join(parts)}")
    if classifier.changed:
        for subj in classifier.changed:
            changed_section.append(f"- {subj}")
    fixed_section: List[str] = [f"- {s}" for s in classifier.fixed]

    # Deduplicate lines while preserving order within each section
    def dedupe(seq: List[str]) -> List[str]:
        seen = set()
        out = []
        for item in seq:
            if item not in seen:
                seen.add(item)
                out.append(item)
        return out

    added_section = dedupe(added_section)
    changed_section = dedupe(changed_section)
    fixed_section = dedupe(fixed_section)

    if added_section:
        md.append("\n### Added")
        md.extend(added_section)
    if changed_section:
        md.append("\n### Changed")
        md.extend(changed_section)
    if fixed_section:
        md.append("\n### Fixed")
        md.extend(fixed_section)
    md.append("")
    return "\n".join(md)


def parse_args(argv: List[str]):
    p = argparse.ArgumentParser(description="Generate CHANGELOG fragment between base tag and target ref")
    p.add_argument("--base-tag", required=True, help="Existing git tag serving as the base (exclusive)")
    p.add_argument("--target", default="HEAD", help="Target ref/branch (default: HEAD)")
    p.add_argument("--version", help="Version string for heading (omit to insert <X.Y.Z>)")
    p.add_argument("--date", help="Override date (YYYY-MM-DD); default today UTC")
    return p.parse_args(argv)


def main(argv: List[str]):
    args = parse_args(argv)
    if not tag_exists(args.base_tag):
        print(f"[error] base tag '{args.base_tag}' not found", file=sys.stderr)
        return 2
    date = args.date or _dt.datetime.utcnow().strftime("%Y-%m-%d")
    commits = list_commits(args.base_tag, args.target)
    classifier = Classifier()
    for subj in commits:
        classifier.classify_commit(subj)
    ns_rows = diff_name_status(args.base_tag, args.target)
    new_policies, modified_policies = detect_policy_file_changes(ns_rows)
    changed_files = [p for _, p in ns_rows]
    map_changes = map_policy_changes(args.base_tag, args.target, changed_files)
    md = build_markdown(args.version, date, classifier, new_policies, modified_policies, map_changes)
    print(md)
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
