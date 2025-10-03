#!/usr/bin/env python3
"""Audit quality of links in policy metadata files.

Checks:
 1. Empty links arrays (should be rare now) -> warn.
 2. Duplicate URLs per policy and globally.
 3. Non-HTTPS URLs.
 4. Potential versioned spec URLs that look outdated (e.g., older PCI/GDPR versions) heuristic.
 5. Domain grouping (to see over-reliance on a single secondary source).
 6. Optional live HEAD check (--live) with concurrency (skipped by default for speed).

Outputs summary plus optional JSON report (--json out.json).

Exit code: 0 always (informational) unless --strict, then non-zero if any issues.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List, Set, Tuple

from tools.lib.metadata_loader import load_all_metadata


POLICY_ROOT = Path("policies")

VERSION_HINT_PATTERNS = [
    re.compile(r"pci[-_]?dss[-_]?v?3\.[12]", re.I),  # old PCI 3.x
    re.compile(r"gdpr\b.*2016", re.I),
    re.compile(r"fatf[-_/]recommendations\b.*2012", re.I),
]

HEADERS = {"User-Agent": "rulehub-link-audit/1.0"}

try:  # pragma: no cover
    import requests  # type: ignore
except Exception:  # pragma: no cover
    requests = None  # type: ignore


def iter_metadata() -> List[Tuple[str, Path, dict]]:
    return load_all_metadata(str(POLICY_ROOT))


def audit(live: bool, timeout: float, workers: int) -> dict:
    policies = iter_metadata()
    issues: Dict[str, List[str]] = defaultdict(list)
    global_urls: Dict[str, Set[str]] = defaultdict(set)  # url -> set(policy ids)
    per_policy_dupes = 0
    non_https = []
    outdated_hints = []
    empty_links = 0

    for pid, path, data in policies:
        links = data.get("links") or []
        if not links:
            empty_links += 1
            issues[pid].append("no_links")
            continue
        seen: Set[str] = set()
        for url in links:
            if not isinstance(url, str):
                continue
            url_s = url.strip()
            if url_s in seen:
                per_policy_dupes += 1
                issues[pid].append(f"duplicate:{url_s}")
            else:
                seen.add(url_s)
            global_urls[url_s].add(pid)
            if url_s.startswith("http://"):
                non_https.append(url_s)
            for pat in VERSION_HINT_PATTERNS:
                if pat.search(url_s):
                    outdated_hints.append(url_s)

    # Global duplicates (same URL used in many policies is OK, but list top shared)
    shared = {u: pids for u, pids in global_urls.items() if len(pids) > 5}

    live_results = {}
    if live and requests is not None:

        def head(url: str):
            try:
                r = requests.head(url, allow_redirects=True, timeout=timeout, headers=HEADERS)  # type: ignore
                return url, getattr(r, "status_code", None), getattr(r, "url", None)
            except Exception as e:  # pragma: no cover
                return url, None, str(e)

        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as ex:
            for url, sc, final in ex.map(head, list(global_urls.keys())):
                live_results[url] = {"status": sc, "final": final}
                if sc and sc >= 400:
                    issues.setdefault("_live", []).append(f"dead:{url}:{sc}")

    domain_counter = Counter()
    for url in global_urls:
        m = re.match(r"https?://([^/]+)/", url + "/")
        if m:
            domain_counter[m.group(1).lower()] += 1

    report = {
        "policy_count": len(policies),
        "policies_without_links": empty_links,
        "per_policy_duplicate_link_occurrences": per_policy_dupes,
        "non_https_urls": sorted(set(non_https)),
        "outdated_version_hints": sorted(set(outdated_hints)),
        "top_shared_urls": sorted(
            [
                {"url": u, "count": len(pids), "sample_policies": sorted(list(pids))[:10]}  # cap sample
                for u, pids in shared.items()
            ],
            key=lambda x: x["count"],
            reverse=True,
        )[:25],
        "top_domains": domain_counter.most_common(25),
        "live": live_results if live else None,
        "issues_index": issues,
    }
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description="Audit policy metadata links")
    ap.add_argument("--live", action="store_true", help="Perform live HEAD requests (slow)")
    ap.add_argument("--timeout", type=float, default=5.0)
    ap.add_argument("--workers", type=int, default=16)
    ap.add_argument("--json", type=Path, help="Write full JSON report to file")
    ap.add_argument("--summary", action="store_true", help="Print human summary")
    ap.add_argument("--strict", action="store_true", help="Exit non-zero if any issues found")
    args = ap.parse_args()

    rep = audit(live=args.live, timeout=args.timeout, workers=args.workers)

    if args.json:
        args.json.write_text(json.dumps(rep, indent=2), encoding="utf-8")
    if args.summary:
        print(f"Policies: {rep['policy_count']}")
        print(f"Policies without links: {rep['policies_without_links']}")
        print(f"Per-policy duplicate link occurrences: {rep['per_policy_duplicate_link_occurrences']}")
        print(f"Non-HTTPS URLs: {len(rep['non_https_urls'])}")
        print(f"Outdated version hints: {len(rep['outdated_version_hints'])}")
        print("Top domains:")
        for dom, cnt in rep['top_domains'][:10]:
            print(f"  {dom}: {cnt}")
    if args.strict and (
        rep['policies_without_links'] > 0 or rep['per_policy_duplicate_link_occurrences'] > 0 or rep['non_https_urls']
    ):
        return 1
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
