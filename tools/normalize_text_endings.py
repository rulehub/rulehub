#!/usr/bin/env python3
"""
Normalize repository text files to LF endings and ensure a trailing newline.
Skips binary-like files and excluded directories. Operates only on git-tracked files.
"""
from __future__ import annotations

import subprocess
from pathlib import Path


EXCLUDE_PREFIXES = (
    "dist/",
    "site/",
    "node_modules/",
    ".venv/",
    "build/",
)

TEXT_EXTS = {
    ".md", ".yml", ".yaml", ".json", ".rego", ".py", ".toml", ".ini", ".mk", ".sh", ".txt", ".csv",
}


def is_text_file(p: Path) -> bool:
    return p.suffix.lower() in TEXT_EXTS


def main() -> int:
    out = subprocess.check_output(["bash", "-lc", "git ls-files"]).decode()
    files = [Path(x) for x in out.splitlines() if x]
    changed = 0
    for p in files:
        sp = str(p).replace("\\", "/")
        if any(sp.startswith(prefix) for prefix in EXCLUDE_PREFIXES):
            continue
        if not is_text_file(p):
            continue
        try:
            raw = p.read_bytes()
        except Exception:
            continue
        try:
            s = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue
        s2 = s.replace("\r\n", "\n").replace("\r", "\n")
        if not s2.endswith("\n"):
            s2 += "\n"
        if s2 != s:
            p.write_text(s2, encoding="utf-8")
            changed += 1
    print(f"Normalized endings for {changed} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
