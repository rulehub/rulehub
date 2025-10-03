#!/usr/bin/env python3
"""Generate an aggregated references index markdown from policy metadata.

Scans the policies/ tree for metadata.yaml files matching the policy metadata schema
and builds docs/references-index.md with a table of policy id, regions, countries,
scope, and sources (links).

Exit codes:
 0 success
 1 policies found without links
 2 other error
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, TypedDict
from urllib.parse import urlparse

import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]
POLICIES_DIR = REPO_ROOT / "policies"
DOCS_MD = REPO_ROOT / "docs" / "references-index.md"
DIST_JSON = REPO_ROOT / "dist" / "references-index.json"
CACHE_FILE = REPO_ROOT / ".cache_refs_index.hash"


def find_metadata_files() -> List[Path]:
    return [p for p in POLICIES_DIR.rglob("metadata.yaml")]


class PolicyMeta(TypedDict, total=False):
    id: str
    links: List[str]
    geo: Dict[str, Any]


def load_yaml(path: Path) -> PolicyMeta:
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):  # type: ignore[unreachable]
        return {}  # type: ignore[return-value]
    return data  # type: ignore[return-value]


def compute_hash(paths: List[Path]) -> str:
    h = hashlib.sha256()
    for p in sorted(paths):
        h.update(p.read_bytes())
    return h.hexdigest()


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    ap = argparse.ArgumentParser(description="Generate references index from policy metadata")
    ap.add_argument("--min-dup", type=int, default=5, help="Min count threshold to list duplicate links")
    ap.add_argument("--format", choices=["md", "json", "both"], default="md")
    ap.add_argument("--fail-missing-links", action="store_true", help="Exit non-zero if any policy missing links")
    ap.add_argument("--no-cache", action="store_true", help="Ignore/change cache and force regeneration")
    return ap.parse_args(argv)


FATF_TYPO_PATTERN = re.compile(r"/Fatfrecommendations/", re.IGNORECASE)


def canonicalize_url(url: str) -> str:
    """Return a canonical form for known problematic URLs (currently FATF typos)."""
    # Normalize the repeated FATF typo segment '/Fatfrecommendations/' -> '/Fatf-recommendations/'
    new = FATF_TYPO_PATTERN.sub("/Fatf-recommendations/", url)
    return new


def validate_link(url: str, original_url: Optional[str] = None) -> List[str]:
    issues: List[str] = []
    # We consider http insecure even after canonicalization
    if url.startswith("http://"):
        issues.append("insecure-http")
    # Only flag FATF typo if we actually transformed the original
    if original_url and original_url != url and "/Fatfrecommendations/" in original_url:
        # We fixed it silently; don't emit a warning (user requested removal)
        pass
    return issues


def shorten_for_display(url: str, max_len: int = 70) -> str:
    """Produce a shortened display string with tooltip preserving full URL.

    Strategy: drop scheme, keep domain + first path segments until max_len; append ellipsis.
    Returns an HTML anchor suitable for embedding inside the markdown table.
    """
    parsed = urlparse(url)
    disp = parsed.netloc + parsed.path
    if len(disp) > max_len:
        disp = disp[: max_len - 1] + "…"
    # Use original URL in title for tooltip
    return f"<a href=\"{url}\" title=\"{url}\">{disp}</a>"


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    meta_files = find_metadata_files()
    current_hash = compute_hash(meta_files)
    if not args.no_cache and CACHE_FILE.exists():
        if CACHE_FILE.read_text().strip() == current_hash and args.format in ("md", "both") and DOCS_MD.exists():
            print("No changes in metadata; skipping regeneration (cache hit)")
            if args.format in ("json", "both") and DIST_JSON.exists():
                return 0
    metas: List[Dict[str, Any]] = []
    missing_links: List[str] = []
    link_occurrences: Dict[str, int] = {}
    link_issues: Dict[str, List[str]] = {}
    for meta_path in meta_files:
        data = load_yaml(meta_path)
        pid = str(data.get("id") or meta_path.parent.name)
        links_val = data.get("links")
        links: List[str] = [str(x) for x in links_val] if isinstance(links_val, list) else []
        if not links:
            missing_links.append(pid)
        geo_val = data.get("geo")
        geo: Dict[str, Any] = geo_val if isinstance(geo_val, dict) else {}
        regions_list: Any = geo.get("regions") if geo else []
        if not isinstance(regions_list, list):
            regions_list = []
        # type: ignore[assignment]
        regions: List[str] = [str(x) for x in regions_list]
        countries_list: Any = geo.get("countries") if geo else []
        if not isinstance(countries_list, list):
            countries_list = []
        # type: ignore[assignment]
        countries: List[str] = [str(x) for x in countries_list]
        scope_val = geo.get("scope") if geo else None
        scope: str = str(scope_val) if isinstance(scope_val, str) else ""
        normalized_links: List[str] = []
        for original in links:
            norm = canonicalize_url(original)
            normalized_links.append(norm)
            link_occurrences[norm] = link_occurrences.get(norm, 0) + 1
            issues = validate_link(norm, original_url=original)
            if issues:
                link_issues[norm] = issues
        links = normalized_links
        metas.append(
            {
                "id": pid,
                "regions": regions,
                "countries": countries,
                "scope": scope,
                "links": links,
            }
        )
    metas.sort(key=lambda x: x["id"])  # deterministic

    # Build MD if needed
    if args.format in ("md", "both"):
        header = "# References Index (Generated)\n\n"
        note = "> This file is auto-generated from policy metadata. Do not edit manually.\n\n"
        table_header = "| Policy ID | Regions | Countries | Scope | Sources |\n|---|---|---|---|---|\n"
        lines = [header, note, table_header]
        for m in metas:
            sources_md = "<br>".join(shorten_for_display(u) for u in m["links"]) if m["links"] else ""
            lines.append(
                "| `{id}` | {regions} | {countries} | {scope} | {sources} |\n".format(
                    id=m["id"],
                    regions=", ".join(m["regions"]),
                    countries=", ".join(m["countries"]),
                    scope=m["scope"],
                    sources=sources_md,
                )
            )
        total_policies = len(metas)
        policies_with_links = sum(1 for m in metas if m["links"])
        unique_links = len(link_occurrences)
        duplicates: List[Tuple[str, int]] = [
            (u, c) for u, c in sorted(link_occurrences.items(), key=lambda x: (-x[1], x[0])) if c > args.min_dup
        ]
        lines.append("\n## Summary\n\n")
        lines.append(f"Total policies: {total_policies}\n\n")
        lines.append(f"Policies with links: {policies_with_links}\n\n")
        lines.append(f"Unique source URLs: {unique_links}\n\n")
        if duplicates:
            lines.append(f"Frequent URLs (count > {args.min_dup}):\n\n")
            for url, count in duplicates:
                lines.append(f"- {url} (x{count})\n")
            lines.append("\n")
        # No 'missing geo' section needed now that geo is enforced.
        if link_issues:
            lines.append("Link issues (heuristic): \n")
            for url, issues in link_issues.items():
                lines.append(f"- {url}: {', '.join(issues)}\n")
            lines.append("\n")
        DOCS_MD.write_text("".join(lines), encoding="utf-8")

    # Build JSON if needed
    if args.format in ("json", "both"):
        DIST_JSON.parent.mkdir(parents=True, exist_ok=True)
        json.dump(
            {
                "policies": metas,
                "missing_links": missing_links,
                "link_occurrences": link_occurrences,
                "link_issues": link_issues,
            },
            DIST_JSON.open("w", encoding="utf-8"),
            indent=2,
        )

    CACHE_FILE.write_text(current_hash, encoding="utf-8")

    if args.fail_missing_links and missing_links:
        sys.stderr.write(f"Policies missing links ({len(missing_links)}): " + ", ".join(missing_links) + "\n")
        return 1
    return 0


if __name__ == "__main__":  # pragma: no cover
    try:
        rc = main()
    except Exception as e:  # noqa: BLE001
        sys.stderr.write(f"ERROR: {e}\n")
        rc = 2
    sys.exit(rc)
