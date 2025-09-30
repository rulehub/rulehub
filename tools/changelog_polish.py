#!/usr/bin/env python3
"""changelog_polish.py

Scan CHANGELOG.md for an Unreleased section, categorize entries and produce a
polished changelog summary and highlight bullets.

Outputs: dist/release/changelog_polished.md

Optional: --apply will replace the Unreleased section in CHANGELOG.md with
the polished content (backup created as CHANGELOG.md.bak.TIMESTAMP).

This is intentionally dependency-free (stdlib only) and includes graceful
handling when there are no unreleased entries.
"""
from __future__ import annotations

import argparse
import re
import shutil
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple


CATEGORY_HEADERS = [
    "Added",
    "Changed",
    "Fixed",
    "Removed",
    "Security",
    "Docs",
    "Performance",
    "Other",
]


def read_changelog(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def find_unreleased_section(text: str) -> Tuple[int, int, str]:
    """Return (start_idx, end_idx, section_text). If not found, start_idx=end_idx=-1
    start_idx is the index of the first character after the Unreleased header line.
    end_idx is the index where the Unreleased section ends (start of next top-level header)"""
    # Match headings like '## [Unreleased]' or '## Unreleased' (case-insensitive)
    m = re.search(r"^##+\s*\[?Unreleased\]?\s*$", text,
                  flags=re.IGNORECASE | re.MULTILINE)
    if not m:
        return -1, -1, ""
    start = m.end()
    # find next top-level '## ' header after start (exactly two hashes) so that
    # sub-headers like '###' remain part of the Unreleased section
    m2 = re.search(r"^##\s+", text[start:], flags=re.MULTILINE)
    end = start + m2.start() if m2 else len(text)
    return start, end, text[start:end]


def categorize_lines(section_text: str) -> Dict[str, List[str]]:
    # Split into lines and handle two common patterns:
    # 1) Sub-headers inside unreleased: '### Added' followed by list items
    # 2) Flat bullet list with prefixes like 'Added: ...' or 'Added - ...'
    lines = section_text.splitlines()
    categories: Dict[str, List[str]] = defaultdict(list)

    current_cat = None
    bullet_re = re.compile(r"^\s*[-*+]\s+(.*)$")
    inline_cat_pattern = r"^(?P<cat>{})\s*[:\-]\s*(?P<rest>.+)$".format(
        "|".join(CATEGORY_HEADERS))
    inline_cat_re = re.compile(inline_cat_pattern, flags=re.IGNORECASE)
    header_re = re.compile(r"^###+\s*(?P<h>.+)$")

    for ln in lines:
        ln_strip = ln.strip()
        if not ln_strip:
            continue
        # detect sub-header
        mh = header_re.match(ln_strip)
        if mh:
            h = mh.group("h").strip()
            # normalize known headers
            for cat in CATEGORY_HEADERS:
                if h.lower().startswith(cat.lower()):
                    current_cat = cat
                    break
            else:
                current_cat = None
            continue

        # detect bullet
        mb = bullet_re.match(ln)
        if mb:
            content = mb.group(1).strip()
            # inline category?
            mi = inline_cat_re.match(content)
            if mi:
                cat = next((c for c in CATEGORY_HEADERS if c.lower()
                           == mi.group("cat").lower()), "Other")
                categories[cat].append(mi.group("rest").strip())
            elif current_cat:
                categories[current_cat].append(content)
            else:
                categories["Other"].append(content)
            continue

        # line may be a wrapped bullet (continuation) - attach to last category if any
        if current_cat and categories[current_cat]:
            categories[current_cat][-1] += " " + ln_strip
        elif categories["Other"]:
            categories["Other"][-1] += " " + ln_strip

    return categories


def generate_summary(categories: Dict[str, List[str]]) -> Tuple[str, List[str]]:
    # produce a 280-char summary and up to 6 highlight bullets
    counts = {k: len(v) for k, v in categories.items()}
    parts = [f"{v} {k.lower()}" for k, v in counts.items() if v > 0]
    # Declare highlights once with a type annotation to satisfy mypy
    highlights: List[str] = []
    if not parts:
        summary = "No unreleased changes."
        return summary, highlights

    # sort parts by count desc
    parts.sort(key=lambda s: int(s.split()[0]), reverse=True)
    summary = "; ".join(parts)
    # keep under 280 chars; if too long, just provide top three counts
    if len(summary) > 280:
        top = parts[:3]
        summary = ", ".join(top)
    # Craft a short leading sentence
    summary = f"Unreleased changes: {summary}."

    # up to 6 highlight bullets: pick first items from largest categories
    # sort categories by size
    cats_sorted = sorted(categories.items(),
                         key=lambda kv: len(kv[1]), reverse=True)
    for cat, items in cats_sorted:
        for it in items:
            if len(highlights) >= 6:
                break
            highlights.append(f"{cat}: {it}")
        if len(highlights) >= 6:
            break

    return summary, highlights


def render_polished(categories: Dict[str, List[str]], summary: str, highlights: List[str]) -> str:
    parts: List[str] = []
    parts.append("# Polished Unreleased Changelog\n")
    parts.append(f"{summary}\n")
    if highlights:
        parts.append("## Highlights\n")
        for h in highlights:
            parts.append(f"- {h}\n")
        parts.append("\n")

    for cat in CATEGORY_HEADERS:
        items = categories.get(cat, [])
        if not items:
            continue
        parts.append(f"## {cat}\n")
        for it in items:
            parts.append(f"- {it}\n")
        parts.append("\n")

    # If no categorized entries, graceful message
    if not any(categories.values()):
        parts = ["# Polished Unreleased Changelog\n\n",
                 "No unreleased changes found.\n"]

    return "\n".join(parts)


def write_output(dest: Path, content: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content, encoding="utf-8")


def backup_file(path: Path) -> Path:
    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    bak = path.with_name(path.name + ".bak." + ts)
    shutil.copy2(path, bak)
    return bak


def apply_to_changelog(changelog_path: Path, polished_text: str) -> None:
    text = changelog_path.read_text(encoding="utf-8")
    start, end, _ = find_unreleased_section(text)
    if start == -1:
        raise RuntimeError("No Unreleased section found to apply to")
    new_text = text[:start] + "\n" + polished_text + "\n" + text[end:]
    changelog_path.write_text(new_text, encoding="utf-8")


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Polish the Unreleased section of CHANGELOG.md")
    parser.add_argument("--changelog", type=Path,
                        default=Path("CHANGELOG.md"), help="Path to CHANGELOG.md")
    parser.add_argument(
        "--out", type=Path, default=Path("dist/release/changelog_polished.md"), help="Output path")
    parser.add_argument(
        "--apply",
        action="store_true",
        help=(
            "Apply polished section back to CHANGELOG.md (creates backup)"
        ),
    )
    args = parser.parse_args(argv)

    changelog = args.changelog
    if not changelog.exists():
        print(f"Changelog not found at {changelog}")
        return 2

    text = read_changelog(changelog)
    start, end, section_text = find_unreleased_section(text)
    if start == -1:
        # write graceful output
        out = "# Polished Unreleased Changelog\n\nNo unreleased changes found.\n"
        write_output(args.out, out)
        print("No Unreleased section found. Wrote graceful output.")
        return 0

    categories = categorize_lines(section_text)
    summary, highlights = generate_summary(categories)
    polished = render_polished(categories, summary, highlights)
    write_output(args.out, polished)
    print(f"Wrote polished changelog to {args.out}")

    if args.apply:
        bak = backup_file(changelog)
        apply_to_changelog(changelog, polished)
        print(
            f"Backed up original changelog to {bak} and applied polished section")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
