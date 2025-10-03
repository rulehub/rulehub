#!/usr/bin/env python3
"""Lightweight local link checker fallback.

- Scans provided directories/files for markdown links
- HEAD/GET request to verify availability (2xx/3xx ok)
- Respects simple excludes for paths and URLs
- Prints a short report and returns non-zero on failures

This is a best-effort replacement when Docker/lychee is unavailable locally.
Use CI lychee for authoritative checks.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import os
import re
import sys
from pathlib import Path
from typing import Iterable, List, Set, Tuple

import requests


# Basic [text](url) matcher; ignores optional titles and images
MD_LINK_RE = re.compile(r"\[(?P<text>[^\]]+)\]\((?P<url>[^)\s]+)\)")


def iter_md_files(inputs: List[str], exclude_paths: Set[str]) -> Iterable[Path]:
    for src in inputs:
        p = Path(src)
        if p.is_dir():
            for f in p.rglob("*.md"):
                if any(str(f).startswith(ex) for ex in exclude_paths):
                    continue
                yield f
        elif p.is_file() and p.suffix == ".md":
            if any(str(p).startswith(ex) for ex in exclude_paths):
                continue
            yield p


def find_links(md_path: Path) -> List[Tuple[int, str]]:
    out: List[Tuple[int, str]] = []
    try:
        for i, line in enumerate(md_path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1):
            for m in MD_LINK_RE.finditer(line):
                out.append((i, m.group("url")))
    except Exception:
        pass
    return out


def check_url(url: str, timeout: float = 10.0) -> Tuple[str, bool, int]:
    if url.startswith("#") or "://" not in url:
        return (url, True, 0)  # skip intra-doc and relative for now
    try:
        resp = requests.head(url, allow_redirects=True, timeout=timeout)
        if resp.status_code >= 400:
            resp = requests.get(url, allow_redirects=True, timeout=timeout)
        ok = resp.status_code < 400
        return (url, ok, resp.status_code)
    except requests.RequestException:
        return (url, False, 0)


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+", help="Files or directories (markdown)")
    ap.add_argument("--exclude-path", action="append", default=[])
    ap.add_argument("--exclude-url", action="append", default=[])
    args = ap.parse_args(argv)

    exclude_paths = {str(Path(p).resolve()) for p in args.exclude_path}
    exclude_urls = set(args.exclude_url)

    md_files = list(iter_md_files(args.inputs, exclude_paths))
    failures = []

    def task(file: Path) -> Tuple[Path, List[Tuple[int, str, bool, int]]]:
        res: List[Tuple[int, str, bool, int]] = []
        for ln, url in find_links(file):
            if any(url.startswith(ex) for ex in exclude_urls):
                continue
            u, ok, code = check_url(url)
            res.append((ln, u, ok, code))
        return (file, res)

    with concurrent.futures.ThreadPoolExecutor(max_workers=min(16, os.cpu_count() or 4)) as ex:
        for file, results in ex.map(task, md_files):
            for ln, u, ok, code in results:
                if not ok:
                    failures.append((file, ln, u, code))

    if failures:
        print("[link-check-fallback] Failures:")
        for file, ln, u, code in failures:
            code_s = str(code) if code else "ERR"
            print(f"- {file}:{ln} -> {u} [{code_s}]")
        return 1
    print("[link-check-fallback] OK (no failures)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
