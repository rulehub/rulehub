#!/usr/bin/env python3
"""Heuristic link audit and discrepancy report.

Provides two main analyses (no network calls):
  1. Suspicious / potentially low-quality links across all metadata (and optional export
      file) using pattern heuristics.
  2. Discrepancies between metadata link sets and links_export.json (missing_in_metadata,
      missing_in_export).
  3. (Optional) Trend history CSV maintenance when --history PATH is supplied. Appends a
     daily row of category counts (idempotent for a given date).

Exit codes:
    0 success (report printed)
    2 usage error / bad args
    5 findings present when FAIL_LINK_AUDIT=1

Usage examples:
    python tools/analyze_links.py --export links_export.json
    python tools/analyze_links.py --export links_export.json --json report.json
    python tools/analyze_links.py --export links_export.json --history links_audit_history.csv

Heuristics (suspicious):
    - Non-HTTPS URLs
    - Vendor/blog or marketing domains (configurable list below)
    - URL length > 180 chars
    - Query strings with tracking parameters (utm_, gclid)
    - Duplicate link reused across > 50 distinct policies
    - Potentially versioned CELEX PDFs (contains 'TXT/PDF')
        - High-risk external source code hosts or archive artifacts (raw.githubusercontent.com,
            gist.github.com, .zip/.tar.* endings)
    - Obsolete FATF/GDPR versions patterns reused (leverages existing regex in audit_links if desired)

The script is read-only.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any, Dict, List, Set
from urllib.parse import urlparse


# Attempt standard intra-repo import (may be shadowed by external 'tools' package)
try:
    from tools.lib import load_all_metadata  # type: ignore
except Exception:  # pragma: no cover - fallback path logic
    REPO_ROOT = Path(__file__).resolve().parent.parent
    if str(REPO_ROOT) not in sys.path:
        sys.path.insert(0, str(REPO_ROOT))
    from tools.lib import load_all_metadata  # type: ignore


POLICY_ROOT = Path("policies")

VENDOR_DOMAINS = {
    "sportradar.com",
    "emvco.com",
    "styra.com",
    "upguard.com",
}
VENDOR_POLICY_FILE = Path("links_vendor_policies.json")
TRACKING_PARAM_RE = re.compile(r"[?&](utm_[a-z]+|gclid)=", re.I)
LONG_URL_THRESHOLD = 180
EXTERNAL_SOURCE_HOSTS = {"raw.githubusercontent.com", "gist.github.com"}
EXTERNAL_SOURCE_EXTS = (
    ".zip",
    ".tar.gz",
    ".tgz",
    ".tar",
    ".tar.bz2",
    ".tar.xz",
)


def load_metadata() -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for pid, meta_path, data in load_all_metadata(str(POLICY_ROOT)):
        links = [u for u in (data.get("links") or []) if isinstance(u, str)]
        out.append({"id": pid, "links": links})
    return out


def load_export(path: Path | None) -> Dict[str, List[str]]:
    if not path:
        return {}
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    out: Dict[str, List[str]] = {}
    policies = data.get("policies") if isinstance(data, dict) else None
    if isinstance(policies, list):
        for p in policies:
            if not isinstance(p, dict):
                continue
            pid = p.get("id")
            if not isinstance(pid, str):
                continue
            links = [u for u in p.get("links", []) if isinstance(u, str)]
            out[pid] = links
    return out


def load_vendor_policies() -> tuple[Set[str], Set[str]]:
    """Load allow/deny vendor domain policies.

    Returns a tuple (allowed, disallowed). If policy file missing or invalid,
    all configured vendor domains are treated as disallowed.
    """
    if not VENDOR_POLICY_FILE.is_file():
        return set(), set(VENDOR_DOMAINS)
    try:
        raw = json.loads(VENDOR_POLICY_FILE.read_text(encoding="utf-8"))
    except Exception:
        return set(), set(VENDOR_DOMAINS)
    if not isinstance(raw, dict):  # pragma: no cover - defensive
        return set(), set(VENDOR_DOMAINS)
    allowed: Set[str] = set()
    disallowed: Set[str] = set()
    for dom, cfg in raw.items():
        if not isinstance(dom, str) or not isinstance(cfg, dict):
            continue
        if cfg.get("allowed") is True:
            allowed.add(dom.lower())
        else:
            disallowed.add(dom.lower())
    # Any vendor domains not mentioned get defaulted to disallowed to avoid silent gaps
    for dom in VENDOR_DOMAINS:
        if dom not in allowed and dom not in disallowed:
            disallowed.add(dom)
    return allowed, disallowed


def _hostname(u: str) -> str:
    """Return lower-cased hostname for URL or empty string on failure."""
    try:
        h = urlparse(u).hostname
        return h.lower() if h else ""
    except Exception:
        return ""


def _host_matches_domain(host: str, domain: str) -> bool:
    """True if host equals domain or is a subdomain of it (with dot boundary)."""
    host = (host or "").lower()
    domain = (domain or "").lower()
    return host == domain or host.endswith("." + domain)


def analyze_suspicious(all_links: Dict[str, Set[str]]) -> Dict[str, Any]:
    suspicious: Dict[str, List[str]] = {
        "non_https": [],
        "vendor": [],
        "long": [],
        "tracking_query": [],
        "celex_pdf": [],
        "external_source_code": [],
    }
    allowed_vendor, disallowed_vendor = load_vendor_policies()
    for url, policies in all_links.items():
        if url.startswith("http://"):
            suspicious["non_https"].append(url)
        host = _hostname(url)
        matched = [dom for dom in VENDOR_DOMAINS if _host_matches_domain(host, dom)]
        if matched:
            # Flag only if any matched domain is disallowed (explicit or by default)
            if any(dom in disallowed_vendor for dom in matched):
                suspicious["vendor"].append(url)
        if len(url) > LONG_URL_THRESHOLD:
            suspicious["long"].append(url)
        if TRACKING_PARAM_RE.search(url):
            suspicious["tracking_query"].append(url)
        if "TXT/PDF" in url:
            suspicious["celex_pdf"].append(url)
        # External source code / archives
        lower_url = url.lower()
        if host in EXTERNAL_SOURCE_HOSTS or any(lower_url.endswith(ext) for ext in EXTERNAL_SOURCE_EXTS):
            suspicious["external_source_code"].append(url)
    # Sort & unique
    for k in suspicious:
        suspicious[k] = sorted(set(suspicious[k]))
    # Highly shared duplicates threshold
    duplicates = [{"url": u, "policy_count": len(pids)} for u, pids in all_links.items() if len(pids) > 50]
    duplicates.sort(key=lambda x: x["policy_count"], reverse=True)
    return {"suspicious": suspicious, "highly_shared": duplicates[:50]}


def diff_metadata_export(meta: List[Dict[str, Any]], export: Dict[str, List[str]]):
    missing_in_metadata: Dict[str, List[str]] = {}
    missing_in_export: Dict[str, List[str]] = {}
    for item in meta:
        pid = item["id"]
        m_links = set(item["links"])
        e_links = set(export.get(pid, []))
        only_export = sorted(e_links - m_links)
        only_meta = sorted(m_links - e_links)
        if only_export:
            missing_in_metadata[pid] = only_export
        if only_meta:
            missing_in_export[pid] = only_meta
    return missing_in_metadata, missing_in_export


def build_all_links(meta: List[Dict[str, Any]], export: Dict[str, List[str]]) -> Dict[str, Set[str]]:
    all_links: Dict[str, Set[str]] = {}

    def add(pid: str, url: str):
        all_links.setdefault(url, set()).add(pid)

    for item in meta:
        for u in item["links"]:
            add(item["id"], u)
    for pid, links in export.items():
        for u in links:
            add(pid, u)
    return all_links


def render_human(report: Dict[str, Any]) -> str:
    lines: List[str] = []
    susp = report["suspicious"]
    lines.append("Link Audit Summary:")
    for cat in ["non_https", "vendor", "tracking_query", "celex_pdf", "long", "external_source_code"]:
        lines.append(f"  {cat}: {len(susp[cat])}")
    hs = report["highly_shared"]
    if hs:
        lines.append("  highly_shared (top):")
        for entry in hs[:10]:
            lines.append(f"    - {entry['url']} ({entry['policy_count']} policies)")
    disc = report["discrepancies"]
    lines.append(
        "Discrepancies: missing_in_metadata={} policies, missing_in_export={} policies".format(
            len(disc['missing_in_metadata']), len(disc['missing_in_export'])
        )
    )
    return "\n".join(lines)


def render_markdown(report: Dict[str, Any]) -> str:
    """Render a markdown summary suitable for publishing.

    Format:
      # Link Audit Report
      ## Summary Counts (table)
      ## Suspicious Categories (lists only if non-empty)
      ## Discrepancies (tables of policy -> links)
    """
    susp = report["suspicious"]
    lines: List[str] = []
    lines.append("# Link Audit Report")
    lines.append("")
    lines.append("## Summary Counts")
    lines.append("")
    lines.append("| Category | Count |")
    lines.append("|----------|-------|")
    for cat in ["non_https", "vendor", "tracking_query", "celex_pdf", "long", "external_source_code"]:
        lines.append(f"| {cat} | {len(susp[cat])} |")
    lines.append(f"| highly_shared | {len(report.get('highly_shared', []))} |")
    lines.append("")
    # Suspicious details
    for cat in ["non_https", "vendor", "tracking_query", "celex_pdf", "long", "external_source_code"]:
        urls = susp.get(cat) or []
        if not urls:
            continue
        lines.append(f"## {cat} ({len(urls)})")
        for u in urls[:200]:  # safety cap
            lines.append(f"- {u}")
        if len(urls) > 200:
            lines.append(f"... ({len(urls) - 200} more omitted)")
        lines.append("")
    # Highly shared
    hs = report.get("highly_shared", [])
    if hs:
        lines.append(f"## highly_shared (top {min(10, len(hs))})")
        for entry in hs[:10]:
            lines.append(f"- {entry['url']} ({entry['policy_count']} policies)")
        lines.append("")
    # Discrepancies
    disc = report["discrepancies"]
    for key, title in [
        ("missing_in_metadata", "Links Only In Export"),
        ("missing_in_export", "Links Only In Metadata"),
    ]:
        mapping = disc.get(key, {})
        lines.append(f"## {title} ({len(mapping)})")
        if mapping:
            lines.append("| Policy ID | Links |")
            lines.append("|-----------|-------|")
            for pid, links in sorted(mapping.items()):
                escaped = "<br>".join(links[:20])
                lines.append(f"| {pid} | {escaped} |")
                if len(links) > 20:
                    lines.append(f"| {pid} (continued) | ... {len(links) - 20} more |")
        lines.append("")
    return "\n".join(lines)


def write_history_csv(report: Dict[str, Any], path: Path) -> None:
    """Append (or update) a daily trend row with category counts.

    Columns: date,non_https,vendor,tracking_query,celex_pdf,long,highly_shared,external_source_code
    Idempotent: if a row already exists for today's date, it is replaced (not duplicated).
    """
    categories = [
        "non_https",
        "vendor",
        "tracking_query",
        "celex_pdf",
        "long",
        "highly_shared",
        "external_source_code",
    ]
    today = date.today().isoformat()
    # Derive counts (highly_shared is length of list; others from suspicious)
    counts_map: Dict[str, int] = {c: 0 for c in categories}
    susp = report.get("suspicious", {})
    for c in categories:
        if c == "highly_shared":
            counts_map[c] = len(report.get("highly_shared", []))
        else:
            counts_map[c] = len(susp.get(c, []))
    header = ["date"] + categories
    rows: List[List[str]] = []
    # Read existing file if present
    if path.is_file():
        try:
            with path.open("r", encoding="utf-8", newline="") as f:
                reader = csv.reader(f)
                existing = list(reader)
            # Preserve header if valid
            if existing:
                if [h.strip() for h in existing[0]] == header:
                    rows = existing[1:]
                # header mismatch -> keep raw rows (will rewrite with new header)
                else:
                    # Attempt to detect if first row is actually data (date pattern)
                    rows = existing if existing and existing[0] and existing[0][0].startswith("20") else existing[1:]
        except Exception:  # pragma: no cover - defensive
            rows = []
    # Filter out any existing row for today
    rows = [r for r in rows if not (r and r[0] == today)]
    # Append today's row
    new_row = [today] + [str(counts_map[c]) for c in categories]
    rows.append(new_row)
    # Sort rows by date ascending for consistency
    try:
        rows.sort(key=lambda r: r[0])
    except Exception:
        pass
    # Write file
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def main() -> int:
    ap = argparse.ArgumentParser(description="Heuristic link audit & metadata/export discrepancy report")
    ap.add_argument("--export", help="links_export.json path (optional)")
    ap.add_argument("--json", help="Write full JSON report")
    ap.add_argument(
        "--history",
        help="Append/update daily trend CSV with category counts (links_audit_history.csv)",
    )
    args = ap.parse_args()

    export_path = Path(args.export) if args.export else None
    meta = load_metadata()
    export = load_export(export_path)

    all_links = build_all_links(meta, export)
    susp_part = analyze_suspicious(all_links)
    missing_in_metadata, missing_in_export = diff_metadata_export(meta, export)
    report: Dict[str, Any] = {
        **susp_part,
        "discrepancies": {
            "missing_in_metadata": missing_in_metadata,
            "missing_in_export": missing_in_export,
        },
        "counts": {
            "policies": len(meta),
            "unique_links": len(all_links),
        },
    }

    if args.json:
        Path(args.json).write_text(json.dumps(report, indent=2), encoding="utf-8")
    if args.history:
        try:
            write_history_csv(report, Path(args.history))
        except Exception as e:  # pragma: no cover - non-fatal
            print(f"[history] failed to write history CSV: {e}", file=sys.stderr)
    output_format = os.environ.get("OUTPUT_FORMAT", "human").lower()
    if output_format == "json":
        # Full JSON to stdout (still honor --json file if provided)
        print(json.dumps(report, indent=2))
    elif output_format == "markdown":
        print(render_markdown(report))
    else:
        print(render_human(report))

    # Conditional failure mode: if FAIL_LINK_AUDIT=1 and any suspicious links or discrepancies exist.
    if os.environ.get("FAIL_LINK_AUDIT") == "1":
        suspicious_cats = [
            "non_https",
            "vendor",
            "tracking_query",
            "celex_pdf",
            "long",
            "external_source_code",
        ]
        suspicious_total = sum(len(report["suspicious"][c]) for c in suspicious_cats)
        discrepancies_total = len(report["discrepancies"]["missing_in_metadata"]) + len(
            report["discrepancies"]["missing_in_export"]
        )
        if suspicious_total > 0 or discrepancies_total > 0:
            print(
                f"[link-audit] FAIL: suspicious_total={suspicious_total} discrepancies_policies={discrepancies_total}",
                file=sys.stderr,
            )
            return 5
        print("[link-audit] OK (no suspicious links or discrepancies)")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
