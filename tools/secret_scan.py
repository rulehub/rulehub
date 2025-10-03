#!/usr/bin/env python3
"""Lightweight secret scanner for local runs (no Docker required).

Features:
- Scans tracked/untracked files in the working tree (text files) for common secret patterns.
- Skips typical build/output dirs and respects a local allowlist file (path-based).
- Masks matched values in output. Exits 2 on real findings, 0 when only allowlisted or none.

Allowlist file:
  .secretignore (repo root), one entry per line. Lines may be:
    - exact relative paths to ignore (e.g., .github/act.secrets)
    - glob patterns supported by fnmatch (e.g., **/*.example)
  Lines starting with '#' are comments. Blank lines are ignored.

Note: Do not print full secret values; only masked previews.
"""

from __future__ import annotations

import fnmatch
import os
import re
import sys
from pathlib import Path
from typing import Iterable, List, Tuple


ROOT = Path.cwd()
ALLOWLIST_FILE = ROOT / ".secretignore"

SKIP_DIRS = {
    ".git",
    ".venv",
    "venv",
    "node_modules",
    "dist",
    "site",
    "__pycache__",
    ".mypy_cache",
    ".pytest_cache",
}

# Regex patterns for common secrets; conservative to avoid noise.
PATTERNS: List[Tuple[str, re.Pattern[str]]] = [
    ("aws_access_key_id", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("github_pat", re.compile(r"\bgithub_pat_[0-9A-Za-z_]{82,}\b")),
    ("ghp_token", re.compile(r"\bghp_[0-9A-Za-z]{36}\b")),
    ("slack_token", re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{10,48}\b")),
    ("private_key_pem", re.compile(r"-----BEGIN (?:RSA|DSA|EC|OPENSSH|PRIVATE) PRIVATE KEY-----")),
    (
        "generic_password_assign",
        re.compile(r"\b(PASS(WORD)?|SECRET|TOKEN|API_KEY)\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{12,}\b"),
    ),
]


def load_allowlist() -> List[str]:
    entries: List[str] = []
    if not ALLOWLIST_FILE.exists():
        return entries
    for line in ALLOWLIST_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        entries.append(line)
    return entries


def is_binary(path: Path) -> bool:
    try:
        chunk = path.read_bytes()[:1024]
    except Exception:
        return True
    if b"\0" in chunk:
        return True
    # Heuristic: treat very high-bit content as binary
    text_chars = bytearray({7, 8, 9, 10, 12, 13, 27} | set(range(0x20, 0x100)))
    return bool(chunk and any(c not in text_chars for c in chunk))


def matches_allowlist(path: Path, allow: Iterable[str]) -> bool:
    rel = path.relative_to(ROOT).as_posix()
    for pat in allow:
        if pat == rel:
            return True
        if fnmatch.fnmatch(rel, pat):
            return True
    return False


def scan_file(path: Path) -> List[Tuple[str, int, str]]:
    findings: List[Tuple[str, int, str]] = []
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return findings
    for idx, line in enumerate(text.splitlines(), start=1):
        for name, rx in PATTERNS:
            if rx.search(line):
                findings.append((name, idx, line.strip()))
    return findings


def mask_value(s: str) -> str:
    # mask all but last 4 visible chars of long tokens
    m = re.search(r"([A-Za-z0-9_\-]{8,})", s)
    if not m:
        return "<masked>"
    token = m.group(1)
    return s.replace(token, "*" * max(0, len(token) - 4) + token[-4:])


def main() -> int:
    allow = load_allowlist()
    real: List[Tuple[Path, str, int, str]] = []
    ignored: List[Tuple[Path, str]] = []

    for dirpath, dirnames, filenames in os.walk(ROOT):
        # prune dirs
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            p = Path(dirpath) / fn
            if matches_allowlist(p, allow):
                ignored.append((p, "allowlist"))
                continue
            if is_binary(p):
                continue
            # skip very large files
            try:
                if p.stat().st_size > 2_000_000:
                    continue
            except Exception:
                continue
            findings = scan_file(p)
            for name, line_no, line in findings:
                real.append((p, name, line_no, mask_value(line)))

    if real:
        print("[secrets] Potential secrets detected (masked):", file=sys.stderr)
        for p, name, ln, masked in real:
            print(f"  - {p}:{ln} [{name}] {masked}", file=sys.stderr)
        print(
            "[secrets] Classify each; add precise allowlist entries to .secretignore for false positives.",
            file=sys.stderr,
        )
        return 2

    # report ignored entries (for transparency)
    if ignored:
        print("[secrets] Ignored by allowlist:")
        for p, why in ignored:
            print(f"  - {p} ({why})")
    else:
        print("[secrets] No findings.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
