#!/usr/bin/env python3
"""List newly added Python dependencies between the last two releases (git tags).

Heuristic:
1. Determine the last two semantic version tags matching v<MAJOR>.<MINOR>.<PATCH>.
2. If fewer than two release tags exist, fall back to the last two commits that touched any
   requirements*.lock file.
3. For each reference, read every requirements*.lock file that exists at that ref.
4. Parse pinned package lines: ``name==version`` (ignoring env markers / hashes / comments).
5. Compute set difference: packages present in NEW ref but absent in OLD ref (by name only).
6. Output a simple report (stdout) in deterministic sorted order.

Usage:
  python tools/diff_new_dependencies.py                # auto-detect refs
  python tools/diff_new_dependencies.py v0.3.0 v0.4.0  # explicit tags/commits (old new)

Exit codes:
  0 always (informational) — suitable for CI reporting without failing the build.
"""

from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from typing import List, Set, Tuple


SEMVER_TAG_RE = re.compile(r"^v(\d+)\.(\d+)\.(\d+)$")
REQ_LINE_RE = re.compile(r"^([A-Za-z0-9_.-]+)==([^#\s]+)")


@dataclass(frozen=True)
class LockDep:
    name: str
    version: str


def run(cmd: List[str]) -> str:
    return subprocess.check_output(cmd, text=True).strip()


def list_release_tags() -> List[str]:
    try:
        raw = run(["git", "tag", "--list", "v*"])
    except subprocess.CalledProcessError:
        return []
    tags = [t for t in raw.splitlines() if SEMVER_TAG_RE.match(t)]

    def ver_key(tag: str):
        m = SEMVER_TAG_RE.match(tag)
        assert m
        return tuple(int(g) for g in m.groups())
    return sorted(tags, key=ver_key)


def fallback_commit_pair() -> Tuple[str, str] | None:
    try:
        raw = run([
            "git",
            "rev-list",
            "HEAD",
            "--max-count=20",
            "--",
            "requirements*.lock",
        ])
    except subprocess.CalledProcessError:
        return None
    commits = raw.splitlines()
    if len(commits) < 2:
        return None
    # rev-list returns newest first
    return commits[1], commits[0]


def gather_lock_files_at_ref(ref: str) -> List[str]:
    try:
        raw = run(["git", "ls-tree", "-r", "--name-only", ref])
    except subprocess.CalledProcessError:
        return []
    return [
        path
        for path in raw.splitlines()
        if path.startswith("requirements") and path.endswith(".lock") and "/" not in path
    ]


def read_file_at_ref(ref: str, path: str) -> str:
    try:
        return run(["git", "show", f"{ref}:{path}"])
    except subprocess.CalledProcessError:
        return ""


def parse_deps(text: str) -> Set[LockDep]:
    deps: Set[LockDep] = set()
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = REQ_LINE_RE.match(line)
        if not m:
            continue
        name, version = m.groups()
        deps.add(LockDep(name.lower(), version))
    return deps


def load_deps_for_ref(ref: str) -> Set[LockDep]:
    deps: Set[LockDep] = set()
    for fname in gather_lock_files_at_ref(ref):
        content = read_file_at_ref(ref, fname)
        deps |= parse_deps(content)
    return deps


def select_refs(argv: List[str]) -> Tuple[str, str]:
    if len(argv) == 3:
        return argv[1], argv[2]
    tags = list_release_tags()
    if len(tags) >= 2:
        return tags[-2], tags[-1]
    fb = fallback_commit_pair()
    if fb:
        return fb
    return "HEAD~1", "HEAD"


def main(argv: List[str]) -> int:
    old_ref, new_ref = select_refs(argv)
    old_deps = load_deps_for_ref(old_ref)
    new_deps = load_deps_for_ref(new_ref)
    old_names = {d.name for d in old_deps}
    additions = sorted(
        [d for d in new_deps if d.name not in old_names], key=lambda d: d.name)
    print(f"Dependency additions (old={old_ref} -> new={new_ref})")
    if not additions:
        print("(none)")
        return 0
    width = max(len(d.name) for d in additions)
    print(f"{'PACKAGE'.ljust(width)}  VERSION")
    for d in additions:
        print(f"{d.name.ljust(width)}  {d.version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
