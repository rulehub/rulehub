#!/usr/bin/env python3
"""
Normalize Markdown files to ASCII-friendly punctuation and spaces.
Replacements:
  – — -> -
  ’ ‘ “ ” -> ' and "
  U+00A0 (NBSP) -> regular space
  U+2192 (RIGHT ARROW) -> ->
Skips code fences (``` blocks) to avoid altering code examples.
Operates on git-tracked *.md files by default.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path


def get_markdown_files() -> list[Path]:
    out = subprocess.check_output(
        ["bash", "-lc", "git ls-files '*.md' '*.MD'"]).decode()
    return [Path(x) for x in out.splitlines() if x]


def normalize_line(s: str) -> str:
    s = s.replace("\u00A0", " ")  # NBSP -> space
    s = s.replace("\u2013", "-").replace("\u2014", "-")  # en/em dash -> hyphen
    s = s.replace("\u2018", "'").replace("\u2019", "'")  # curly single quotes
    s = s.replace("\u201C", '"').replace("\u201D", '"')  # curly double quotes
    s = s.replace("\u2192", "->")  # right arrow
    return s


def normalize_markdown(text: str) -> str:
    lines = text.splitlines(keepends=False)
    out: list[str] = []
    in_fence = False
    fence_re = re.compile(r"^\s*```")
    for line in lines:
        if fence_re.match(line):
            out.append(line)
            in_fence = not in_fence
            continue
        if in_fence:
            out.append(line)
        else:
            out.append(normalize_line(line))
    return "\n".join(out) + "\n"


def main() -> int:
    changed = 0
    for p in get_markdown_files():
        try:
            original = p.read_text(encoding="utf-8")
        except Exception:
            continue
        normalized = normalize_markdown(original)
        if normalized != original:
            p.write_text(normalized, encoding="utf-8")
            changed += 1
    print(f"Normalized Markdown in {changed} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
