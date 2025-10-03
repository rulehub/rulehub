#!/usr/bin/env python3
"""Validate link audit results against a committed baseline allowlist.

Baseline format (JSON):
{
    "non_https_urls": ["http://example.com/..."],
    "policies_without_links": 0,
    "per_policy_duplicate_link_occurrences": 0,
    "dead_urls": {"https://example.com/missing": 404}
}

Rules:
    - Fails if a new non-HTTPS URL appears that is not in baseline.non_https_urls.
    - Fails if policies_without_links increases above baseline value.
    - Fails if per_policy_duplicate_link_occurrences increases above baseline value.
    - Fails if new dead URLs (HTTP status >=400) are detected that are not in baseline.dead_urls.
    - Decreases are allowed (they will be reported so you can shrink the baseline in a follow-up PR).

If the baseline file does not exist, it will be created from the current state and exit 0
to ease first-time adoption.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict, cast


# Add the parent directory to sys.path so we can import from tools
sys.path.insert(0, str(Path(__file__).parent.parent))

from tools.audit_links import audit  # type: ignore


BASELINE_PATH = Path("links_audit_baseline.json")


def load_baseline() -> Dict[str, Any] | None:
    if not BASELINE_PATH.exists():
        return None
    try:
        return json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    except Exception as e:  # pragma: no cover
        print(f"ERROR: Failed to parse baseline: {e}", file=sys.stderr)
        return None


def write_baseline(rep: Dict[str, Any]) -> None:
    # type: ignore[assignment]
    non_https: list[str] = list(rep.get("non_https_urls", []))
    live_raw = rep.get("live")
    dead_urls: Dict[str, int] = {}
    if isinstance(live_raw, dict):
        for url_obj, meta_obj in live_raw.items():  # type: ignore[assignment]
            url = url_obj if isinstance(url_obj, str) else None
            meta = cast(Any, meta_obj) if isinstance(meta_obj, dict) else None
            if not url or not meta:
                continue
            status = meta.get("status")  # type: ignore[assignment]
            if isinstance(status, int) and status >= 400:
                dead_urls[url] = status
    data: Dict[str, Any] = {
        "non_https_urls": sorted(non_https),
        "policies_without_links": int(rep.get("policies_without_links", 0)),
        "per_policy_duplicate_link_occurrences": int(rep.get("per_policy_duplicate_link_occurrences", 0)),
        "dead_urls": dict(sorted(dead_urls.items())),
    }
    BASELINE_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    # We run audit without live checks for speed; live could be added in a scheduled job.
    # audit() returns a plain dict with known keys; cast to Dict[str, Any] for typing.
    # type: ignore[assignment]
    rep: Dict[str, Any] = audit(live=True, timeout=5.0, workers=16)
    baseline = load_baseline()
    if baseline is None:
        print("Baseline file missing; creating new baseline from current repository state.")
        write_baseline(rep)
        print(f"Created {BASELINE_PATH}.")
        return 0

    failures: list[str] = []
    rep_non_https: list[str] = list(rep.get("non_https_urls", []))  # type: ignore[assignment]
    baseline_non_https: list[str] = list(baseline.get("non_https_urls", []))
    new_non_https: list[str] = sorted(set(rep_non_https) - set(baseline_non_https))
    if new_non_https:
        failures.append(f"New non-HTTPS URLs detected: {len(new_non_https)}")

    if rep["policies_without_links"] > baseline.get("policies_without_links", 0):
        failures.append(
            "policies_without_links increased: {} -> {}".format(
                baseline.get("policies_without_links", 0),
                rep["policies_without_links"],
            )
        )

    if rep["per_policy_duplicate_link_occurrences"] > baseline.get("per_policy_duplicate_link_occurrences", 0):
        failures.append(
            "per_policy_duplicate_link_occurrences increased: {} -> {}".format(
                baseline.get("per_policy_duplicate_link_occurrences", 0),
                rep["per_policy_duplicate_link_occurrences"],
            )
        )

    live_raw = rep.get("live")
    current_dead: Dict[str, int] = {}
    if isinstance(live_raw, dict):
        for url_obj, meta_obj in live_raw.items():  # type: ignore[assignment]
            url = url_obj if isinstance(url_obj, str) else None
            meta = cast(Any, meta_obj) if isinstance(meta_obj, dict) else None
            if not url or not meta:
                continue
            status = meta.get("status")  # type: ignore[assignment]
            if isinstance(status, int) and status >= 400:
                current_dead[url] = status
    baseline_dead: Dict[str, int] = baseline.get("dead_urls", {}) or {}
    new_dead = sorted(set(current_dead) - set(baseline_dead))
    if new_dead:
        failures.append(f"New dead URLs: {len(new_dead)}")

    print("Link Audit Summary:")
    print(f"  non_https_urls: {len(rep_non_https)} (baseline {len(baseline_non_https)})")
    print(
        "  policies_without_links: "
        f"{rep['policies_without_links']} (baseline {baseline.get('policies_without_links', 0)})"
    )
    print(
        "  per_policy_duplicate_link_occurrences: "
        f"{rep['per_policy_duplicate_link_occurrences']} (baseline "
        f"{baseline.get('per_policy_duplicate_link_occurrences', 0)})"
    )
    print(f"  dead_urls: {len(current_dead)} (baseline {len(baseline_dead)})")
    if new_non_https:
        print("  New non-HTTPS URLs:")
        for u in new_non_https[:25]:
            print("    -", u)
    if new_dead:
        print("  New dead URLs (HTTP >=400):")
        for u in new_dead[:25]:
            print(f"    - {u} -> {current_dead[u]}")

    if failures:
        print("FAIL: New link issues detected. Update baseline if intentional.", file=sys.stderr)
        return 1
    print("PASS: No new link issues above baseline.")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
