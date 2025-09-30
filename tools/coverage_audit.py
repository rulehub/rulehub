#!/usr/bin/env python3
"""Audit policy metadata completeness and compliance-map coverage.

Outputs a summary and detailed lists of:
- policies with missing/placeholder name or description
- policies with no links
- orphan policies (not referenced in any compliance map)
- stale policies (coverage empty OR placeholder fields)

Assumptions:
- 'coverage' is interpreted as presence in any file under compliance/maps/*.yml
- Placeholder text is any value containing '<' or the word 'placeholder' (case-insensitive)
"""
import json
import re
from datetime import datetime, timezone
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
POLICY_ROOT = ROOT / "policies"
MAPS_ROOT = ROOT / "compliance" / "maps"

# Wider placeholder patterns: angle-bracket templates, common filler tokens, and short phrases
placeholder_re = re.compile(
    (
        r"<[^>]+>|placeholder|short description|policy title|tbd|tba|todo|"
        r"n/?a|replace(me| this)?|to be (filled|added|completed)|<policy title>|<short description>"
    ),
    re.I,
)


def collect_map_policies(node):
    """Recursively collect strings under keys named 'policies' in a YAML structure."""
    found = []
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "policies" and isinstance(v, list):
                for item in v:
                    if isinstance(item, str):
                        found.append(item.strip())
            else:
                found.extend(collect_map_policies(v))
    elif isinstance(node, list):
        for item in node:
            found.extend(collect_map_policies(item))
    return found


def load_maps():
    """Load all policy ids referenced under 'policies' in YAML map files."""
    ids = set()
    if not MAPS_ROOT.exists():
        return ids
    for p in MAPS_ROOT.glob("*.yml"):
        try:
            data = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        except Exception:
            continue
        for pol in collect_map_policies(data):
            ids.add(pol)
    return ids


def load_exceptions():
    """Load optional exceptions file.

    Look for tools/coverage_exceptions.yaml or coverage_exceptions.yaml at repo root.
    Returns (allowlist_set, domains_dict).
    """
    candidates = [ROOT / "tools" / "coverage_exceptions.yaml",
                  ROOT / "coverage_exceptions.yaml"]
    for p in candidates:
        if p.exists():
            try:
                data = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
            except Exception:
                data = {}
            allow = set()
            for v in data.get("allowlist", []):
                if isinstance(v, str):
                    allow.add(v.strip())
            domains = {}
            for dom, lst in (data.get("domains") or {}).items():
                if isinstance(lst, list):
                    domains[dom] = {item.strip()
                                    for item in lst if isinstance(item, str)}
            return allow, domains
    return set(), {}


def is_placeholder(s, policy_id=None, domain=None, allowlist=None, domain_exceptions=None):
    """Return True if the string looks like a placeholder or template value.

    Heuristics:
    - empty or null
    - matches common placeholder tokens (TBD, TODO, N/A, REPLACEME)
    - angle-bracket templated values like <Policy Title>
    - very short non-descriptive strings (one or two chars)
    """
    # Exceptions override placeholder detection
    if allowlist is None:
        allowlist = set()
    if domain_exceptions is None:
        domain_exceptions = {}
    if policy_id and policy_id in allowlist:
        return False
    if domain and domain in domain_exceptions and policy_id in domain_exceptions[domain]:
        return False

    if s is None:
        return True
    if not isinstance(s, str):
        return False
    s_strip = s.strip()
    if s_strip == "":
        return True
    # Common tokens and explicit templates
    if placeholder_re.search(s_strip):
        return True
    # common short filler words
    low = s_strip.lower()
    if low in {"tbd", "tba", "todo", "n/a", "na", "none", "unknown", "replace me", "replaceme"}:
        return True
    # Excessively short or non-descriptive
    if len(s_strip) <= 2:
        return True
    return False


def main():
    map_ids = load_maps()
    allowlist, domain_exceptions = load_exceptions()

    metas = list(POLICY_ROOT.glob("**/metadata.yaml"))
    total = len(metas)
    rows = []

    for m in sorted(metas):
        try:
            data = yaml.safe_load(m.read_text(encoding="utf-8")) or {}
        except Exception:
            data = {}
        pid = data.get("id") or f"(missing id)@{m.parent.name}"
        name = data.get("name")
        desc = data.get("description")
        links = data.get("links") or []
        links_count = sum(1 for item in links if isinstance(
            item, str) and item.strip() and "<" not in item)
        coverage_count = 1 if pid in map_ids else 0

        # derive domain from path (policies/<domain>/...)
        parts = m.parts
        domain = None
        try:
            idx = parts.index('policies')
            domain = parts[idx + 1]
        except Exception:
            domain = None

        row = {
            "id": pid,
            "path": str(m),
            "name": name,
            "description": desc,
            "links_count": links_count,
            "coverage_count": coverage_count,
            "name_ok": (
                not is_placeholder(
                    name,
                    policy_id=pid,
                    domain=domain,
                    allowlist=allowlist,
                    domain_exceptions=domain_exceptions,
                )
            ),
            "description_ok": (
                not is_placeholder(
                    desc,
                    policy_id=pid,
                    domain=domain,
                    allowlist=allowlist,
                    domain_exceptions=domain_exceptions,
                )
            ),
            "links_ok": links_count >= 1,
            "covered": coverage_count >= 1,
        }
        rows.append(row)

    # Metrics
    name_ok = sum(1 for r in rows if r["name_ok"])
    desc_ok = sum(1 for r in rows if r["description_ok"])
    links_ok = sum(1 for r in rows if r["links_ok"])
    coverage_ok = sum(1 for r in rows if r["covered"])
    all_ok = sum(1 for r in rows if r["name_ok"]
                 and r["description_ok"] and r["links_ok"] and r["covered"])

    def pct(n):
        return f"{(n/total*100):.1f}%" if total else "N/A"

    print("SUMMARY")
    print(f"Total policies (metadata files): {total}")
    print(f"Name populated: {name_ok}/{total} ({pct(name_ok)})")
    print(f"Description populated: {desc_ok}/{total} ({pct(desc_ok)})")
    print(f">=1 link: {links_ok}/{total} ({pct(links_ok)})")
    print(
        f"Covered in compliance maps: {coverage_ok}/{total} ({pct(coverage_ok)})")
    print(f"All checks passed: {all_ok}/{total} ({pct(all_ok)})")
    print()

    # Detailed lists
    orphans = [r for r in rows if not r["covered"]]
    placeholder_rows = [r for r in rows if (
        not r["name_ok"]) or (not r["description_ok"])]
    stale = [r for r in rows if (not r["covered"]) or (
        not r["name_ok"]) or (not r["description_ok"])]

    def print_list(title, items, limit=None):
        print(title)
        if not items:
            print("  (none)")
            print()
            return
        for i, r in enumerate(items):
            if limit and i >= limit:
                print(f"  ...and {len(items)-limit} more")
                break
            flags = []
            if not r["covered"]:
                flags.append("ORPHAN")
            if not r["name_ok"]:
                flags.append("NAME_PLACEHOLDER")
            if not r["description_ok"]:
                flags.append("DESC_PLACEHOLDER")
            if not r["links_ok"]:
                flags.append("NO_LINKS")
            print(f"- {r['id']} ({r['path']}) [{' '.join(flags)}]")
        print()

    print_list("ORPHAN POLICIES (no coverage):", orphans)
    print_list("POLICIES WITH PLACEHOLDER NAME/DESCRIPTION:", placeholder_rows)
    print_list("STALE POLICIES (coverage empty OR placeholder):", stale)

    # Write JSON and Markdown reports to dist/
    out_dir = ROOT / "dist"
    out_dir.mkdir(exist_ok=True)

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total": total,
        "metrics": {
            "name_populated": name_ok,
            "description_populated": desc_ok,
            "links_populated": links_ok,
            "covered": coverage_ok,
            "all_ok": all_ok,
        },
        "rows": rows,
    }

    json_path = out_dir / "policy_coverage_audit.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    md_path = out_dir / "policy_coverage_audit.md"
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(
            f"# Policy coverage audit\nGenerated: {report['generated_at']}\n\n")
        f.write(f"Total policies: {total}\n\n")
        f.write("## Metrics\n\n")
        f.write(f"- Name populated: {name_ok}/{total}\n")
        f.write(f"- Description populated: {desc_ok}/{total}\n")
        f.write(f"- >=1 link: {links_ok}/{total}\n")
        f.write(f"- Covered in compliance maps: {coverage_ok}/{total}\n")
        f.write(f"- All checks passed: {all_ok}/{total}\n\n")

        def write_section(title, items):
            f.write(f"### {title}\n\n")
            if not items:
                f.write("(none)\n\n")
                return
            for r in items:
                flags = []
                if not r["covered"]:
                    flags.append("ORPHAN")
                if not r["name_ok"]:
                    flags.append("NAME_PLACEHOLDER")
                if not r["description_ok"]:
                    flags.append("DESC_PLACEHOLDER")
                if not r["links_ok"]:
                    flags.append("NO_LINKS")
                f.write(f"- `{r['id']}` — {r['path']} — {', '.join(flags)}\n")
            f.write("\n")

        write_section("Orphan policies (no coverage)", orphans)
        write_section(
            "Policies with placeholder name/description", placeholder_rows)
        write_section("Stale policies (coverage empty OR placeholder)", stale)

    # CSV export removed — JSON + Markdown + trimmed Markdown are generated by default

    # Trimmed markdown with only orphans and stale lists for quick review
    trimmed_md = out_dir / "policy_coverage_audit_trimmed.md"
    with open(trimmed_md, "w", encoding="utf-8") as tf:
        tf.write(
            f"# Policy coverage audit — Orphans & Stale\nGenerated: {report['generated_at']}\n\n")

        def write_section_tf(title, items):
            tf.write(f"## {title}\n\n")
            if not items:
                tf.write("(none)\n\n")
                return
            for r in items:
                tf.write(f"- `{r['id']}` — {r['path']}\n")
            tf.write("\n")

        # write orphans and stale
        write_section_tf("Orphan policies (no coverage)", orphans)
        write_section_tf(
            "Stale policies (coverage empty OR placeholder)", stale)

    # Exit code 0
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
