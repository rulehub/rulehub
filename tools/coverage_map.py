#!/usr/bin/env python3
import argparse
import csv
import json
import os
import time
from functools import lru_cache
from pathlib import Path
from typing import Any

import yaml


MAPS_DIR = Path("compliance/maps")
POLICY_ROOT = Path("policies")
OUT_MD = Path("docs/coverage.md")
OUT_HTML = Path("dist/coverage.html")
OUT_INDEX_JSON = Path("dist/policies-index.json")
# Backstage plugin expects this exact path/name
OUT_PLUGIN_INDEX_JSON = Path("dist/index.json")
OUT_COVERAGE_JSON = Path("dist/coverage.json")
OUT_TEST_COVERAGE_JSON = Path("dist/policy-test-coverage.json")
OUT_POLICIES_CSV = Path("dist/policies.csv")  # new optional CSV export

# Schema version for Backstage plugin index (dist/index.json). Increment when the
# structure of the "packages" objects or top-level fields changes in a
# backward-incompatible way. Version 1 corresponds to the pre-versioned
# historical structure (only {"packages": [...]}) which is now emitted with an
# added top-level field: schemaVersion.
SCHEMA_VERSION_DEFAULT = 1


def normalize_paths(p):
    """Return a normalized list of string paths given a string|list|None."""
    if p is None:
        return []
    if isinstance(p, str):
        return [p]
    if isinstance(p, (list, tuple)):
        return [str(x) for x in p]
    return []


def load_metadata_index():
    """Load metadata from policies/**/metadata.yaml.

    Requires explicit 'path' (string or list) to real policy files.
    """
    idx = {}
    for meta in POLICY_ROOT.glob("**/metadata.yaml"):
        with open(meta, "r", encoding="utf-8") as f:
            y = yaml.safe_load(f) or {}
        pid = y.get("id")
        if not pid:
            # derive id from folder names if possible e.g., policies/<standard>/<id>
            try:
                parts = meta.parent.parts
                pol_idx = parts.index("policies")
                std = parts[pol_idx + 1] if len(parts) > pol_idx + 1 else None
                short_id = parts[pol_idx + 2] if len(parts) > pol_idx + 2 else None
                if std and short_id:
                    pid = f"{std}.{short_id}"
                else:
                    continue
            except Exception:
                continue
        paths = normalize_paths(y.get("path"))
        # Support nested standard object {name, version}
        std = y.get("standard")
        std_name = std.get("name") if isinstance(std, dict) else std
        std_ver = std.get("version") if isinstance(std, dict) else y.get("version")
        idx[pid] = {
            "name": y.get("name"),
            "standard": std_name,
            "version": std_ver,
            "path": paths,
            "description": y.get("description"),
            "framework": y.get("framework"),
            "severity": y.get("severity"),
            "owner": y.get("owner"),
            "tags": y.get("tags"),
            "links": y.get("links"),
            "geo": y.get("geo"),
            # Optional jurisdiction array (list of strings). Included if present so
            # downstream catalog consumers (e.g., Backstage plugin) can filter.
            # If absent or null in metadata we omit at package emission time.
            "jurisdiction": y.get("jurisdiction"),
        }
    return idx


def load_mappings():
    maps = []
    for mp in MAPS_DIR.glob("*.yml"):
        with open(mp, "r", encoding="utf-8") as f:
            maps.append(yaml.safe_load(f) or {})
    return maps


@lru_cache(maxsize=4096)
def _path_exists(p: str) -> bool:
    """Cached os.path.exists to reduce repeated filesystem hits for duplicated paths."""
    return os.path.exists(p)


def build_markdown(maps, meta_idx):
    lines = ["# Compliance Coverage", ""]
    for m in maps:
        lines.append(f"## {m.get('regulation')} {m.get('version')}")
        lines.append("")
        lines.append("| Section | Title | Policies | Coverage | Paths |")
        lines.append("|---|---|---|---|---|")
        total = 0
        covered = 0
        sections = m.get("sections") or {}
        for sec, data in sections.items():
            pols = data.get("policies") or []
            # Coverage indicator:
            #   OK   -> all policy ids have metadata
            #   WARN -> some missing (avoid emojis for plain-text environments)
            cov = "OK" if all(pid in meta_idx for pid in pols) and pols else "WARN"
            if pols:
                covered += sum(1 for pid in pols if pid in meta_idx)
                total += len(pols)
            # path icons for each policy id (reuse cached exists)

            def _path_icons(pid: str) -> str:
                paths = (meta_idx.get(pid) or {}).get("path") or []
                if not paths:
                    return f"{pid}: —"
                parts = [("OK" if _path_exists(p) else "MISS") + " " + p for p in paths]
                return f"{pid}: " + ", ".join(parts)

            path_counts = "; ".join(_path_icons(pid) for pid in pols) if pols else ""
            lines.append(f"| `{sec}` | {data.get('title', '')} | {', '.join(pols)} | {cov} | {path_counts} |")
        lines.append("")
        if total:
            pct = int(100 * covered / total)
            lines.append(f"**Coverage**: {covered}/{total} ({pct}%)")
        lines.append("")
    return "\n".join(lines)


def compute_policy_test_coverage(meta_idx):
    """Compute simple Gatekeeper policy test coverage (policy.rego vs policy_test.rego)."""
    policies = []
    for pol in Path("policies").glob("**/policy.rego"):
        test_file = pol.parent / "policy_test.rego"
        policies.append((pol, test_file.exists()))
    total = len(policies)
    tested = sum(1 for _, has in policies if has)
    pct = round(100 * tested / total, 2) if total else 0.0
    missing = [p for p, has in policies if not has]
    data = {
        "tested": tested,
        "total": total,
        "percent": pct,
        "missing": [str(m) for m in missing],
    }
    return data


def build_mermaid(maps, meta_idx):
    g = ["flowchart LR"]
    for m in maps:
        reg = f"{m.get('regulation')} {m.get('version')}"
        reg_id = reg.replace(" ", "_")
        g.append(f'{reg_id}(["{reg}"])')
        for sec, data in (m.get("sections") or {}).items():
            sec_id = f"{reg_id}_{sec.replace('.', '_').replace(' ', '_').replace('(', '').replace(')', '')}"
            g.append(f'{sec_id}["{sec}: {data.get("title", "")}"]')
            g.append(f"{reg_id} --> {sec_id}")
            for pid in data.get("policies") or []:
                node_id = pid.replace(".", "_")
                title = meta_idx.get(pid, {}).get("name", pid)
                present = pid in meta_idx
                # Node style is encoded via Mermaid classes; color is set in doc string below
                g.append(f'{node_id}["{title}\n({pid})"]:::node')
                # Mermaid classDef for coloring
                if present:
                    g.append(f"class {node_id} present;")
                else:
                    g.append(f"class {node_id} missing;")
                g.append(f"{sec_id} --> {node_id}")
    # Define classes at the end
    g.append("classDef present fill:lightgreen,stroke:#333,stroke-width:1px;")
    g.append("classDef missing fill:#ffcccc,stroke:#333,stroke-width:1px;")
    return "\n".join(g)


def validate_paths(meta_idx):
    """Return a dict of id -> list[ {path, exists} ]."""
    result = {}
    for pid, meta in meta_idx.items():
        paths = meta.get("path") or []
        result[pid] = [{"path": p, "exists": bool(_path_exists(p))} for p in paths]
    return result


def build_policies_index(meta_idx, path_status):
    """Return list of policy objects for OUT_INDEX_JSON (no sorting to preserve current order)."""
    policies = []
    for pid, meta in meta_idx.items():
        framework = meta.get("framework")
        severity = meta.get("severity")
        paths = meta.get("path") or []
        if not framework:
            for p in paths:
                if "/kyverno/" in p or p.startswith("addons/kyverno"):
                    framework = "kyverno"
                    break
                if "k8s-gatekeeper" in p or p.startswith("addons/k8s-gatekeeper"):
                    framework = "gatekeeper"
                    break
        if not severity and framework == "kyverno":
            try:
                for p in paths:
                    if not (p.endswith('.yaml') or p.endswith('.yml')):
                        continue
                    with open(p, 'r', encoding='utf-8') as f:
                        y = yaml.safe_load(f) or {}
                    spec = (y or {}).get('spec') or {}
                    vfa = (spec or {}).get('validationFailureAction')
                    if isinstance(vfa, str):
                        severity = 'high' if vfa.lower() == 'enforce' else 'low'
                        break
            except Exception:
                pass
        if not severity and framework == "gatekeeper":
            if any("/constraints/" in p for p in paths):
                severity = "high"
            else:
                severity = "medium"
        policies.append(
            {
                "id": pid,
                "name": meta.get("name"),
                "standard": meta.get("standard"),
                "version": meta.get("version"),
                "description": meta.get("description"),
                "framework": framework,
                "severity": severity,
                "paths": path_status.get(pid, []),
                "geo": meta.get("geo"),
            }
        )
    return policies


def build_coverage(maps, meta_idx, path_status):
    """Return (coverage_list, coverage_by_policy mapping)."""
    cov = []
    coverage_by_policy = {}
    for m in maps:
        reg = {
            "regulation": m.get("regulation"),
            "version": m.get("version"),
            "sections": [],
        }
        total = 0
        covered = 0
        for sec, data in (m.get("sections") or {}).items():
            pols = data.get("policies") or []
            sec_entry = {
                "section": sec,
                "title": data.get("title", ""),
                "policies": [],
            }
            for pid in pols:
                meta = meta_idx.get(pid) or {}
                found = pid in meta_idx
                if found:
                    covered += 1
                total += 1
                sec_entry["policies"].append(
                    {
                        "id": pid,
                        "found": found,
                        "name": meta.get("name"),
                        "paths": path_status.get(pid, []),
                    }
                )
                label = f"{m.get('regulation')} {m.get('version')} {sec}"
                title = data.get("title")
                if title:
                    label = f"{label} — {title}"
                coverage_by_policy.setdefault(pid, []).append(label)
            reg["sections"].append(sec_entry)
        reg["totals"] = {"covered": covered, "total": total}
        cov.append(reg)
    return cov, coverage_by_policy


def write_json_outputs(maps, meta_idx):
    path_status = validate_paths(meta_idx)
    policies = build_policies_index(meta_idx, path_status)
    with open(OUT_INDEX_JSON, "w", encoding="utf-8") as f:
        json.dump({"policies": policies}, f, indent=2, ensure_ascii=False)

    # CSV export (flat) for simple consumption
    # Columns: id,name,standard,version,framework,severity,geo_regions,path_count,paths_joined
    try:
        with open(OUT_POLICIES_CSV, "w", newline="", encoding="utf-8") as fcsv:
            writer = csv.writer(
                fcsv,
                lineterminator='\n',
                quoting=csv.QUOTE_ALL,
            )
            writer.writerow(
                [
                    "id",
                    "name",
                    "standard",
                    "version",
                    "framework",
                    "severity",
                    "geo_regions",
                    "paths_count",
                    "paths",
                ]
            )
            for p in policies:
                geo = p.get("geo") or {}
                regions = ";".join((geo.get("regions") or []) if isinstance(geo, dict) else [])
                paths = p.get("paths") or []
                flat_paths_list = [str(x.get("path")) for x in paths if isinstance(x, dict) and x.get("path")]
                flat_paths = ";".join(flat_paths_list)
                writer.writerow(
                    [
                        p.get("id"),
                        p.get("name"),
                        p.get("standard"),
                        p.get("version"),
                        p.get("framework"),
                        p.get("severity"),
                        regions,
                        len(paths),
                        flat_paths,
                    ]
                )
    except Exception as e:
        # Non-fatal; log but continue.
        print("WARN: failed to write CSV:", e)

    cov, coverage_by_policy = build_coverage(maps, meta_idx, path_status)
    with open(OUT_COVERAGE_JSON, "w", encoding="utf-8") as f:
        json.dump(cov, f, indent=2, ensure_ascii=False)

    packages: list[dict[str, Any]] = [
        {
            "id": pid,
            "name": meta.get("name"),
            "standard": meta.get("standard"),
            "version": meta.get("version"),
            **({"jurisdiction": meta.get("jurisdiction")} if meta.get("jurisdiction") else {}),
            "coverage": coverage_by_policy.get(pid, []),
        }
        for pid, meta in meta_idx.items()
    ]

    # Allow forcing a specific schema version (future use) or disabling the new
    # field via env flags:
    #   RULEHUB_INDEX_SCHEMA_VERSION (int) -> overrides default
    #   RULEHUB_DISABLE_SCHEMA_VERSION=1   -> omit field for consumers expecting earlier output
    schema_version = int(os.environ.get("RULEHUB_INDEX_SCHEMA_VERSION", str(SCHEMA_VERSION_DEFAULT)))
    disable_schema_flag = os.environ.get("RULEHUB_DISABLE_SCHEMA_VERSION", "0") in {"1", "true", "TRUE"}
    if disable_schema_flag:
        index_payload: dict[str, Any] = {"packages": packages}
    else:
        # Include schemaVersion for forward migration; consumers can opt out with env flag.
        index_payload = {"schemaVersion": schema_version, "packages": packages}
    with open(OUT_PLUGIN_INDEX_JSON, "w", encoding="utf-8") as f:
        json.dump(index_payload, f, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description="Generate coverage & index artifacts")
    parser.add_argument("--profile", action="store_true", help="Print timing breakdown stages")
    args = parser.parse_args()

    timings = []

    t0 = time.perf_counter()
    meta_idx = load_metadata_index()
    timings.append(("load_metadata_index", time.perf_counter() - t0))

    t1 = time.perf_counter()
    maps = load_mappings()
    timings.append(("load_mappings", time.perf_counter() - t1))

    t2 = time.perf_counter()
    test_cov = compute_policy_test_coverage(meta_idx)
    timings.append(("compute_policy_test_coverage", time.perf_counter() - t2))

    os.makedirs("docs", exist_ok=True)
    t3 = time.perf_counter()
    md = build_markdown(maps, meta_idx)
    timings.append(("build_markdown", time.perf_counter() - t3))
    md += "\n## Policy Test Coverage (Gatekeeper Rego)\n\n"
    md += f"Policies with tests: {test_cov['tested']}/{test_cov['total']} ({test_cov['percent']}%)\n\n"
    if test_cov["missing"]:
        md += "Missing tests for:\n\n"
        for miss in test_cov["missing"]:
            md += f"- `{miss}`\n"
        md += "\n"
    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write(md)

    os.makedirs("dist", exist_ok=True)
    t4 = time.perf_counter()
    mermaid = build_mermaid(maps, meta_idx)
    timings.append(("build_mermaid", time.perf_counter() - t4))
    html = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>RuleHub Coverage</title>
<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
</head><body>
<h1>Compliance Coverage</h1>
<div class=\"mermaid\">{mermaid}</div>
<script>mermaid.initialize({{ startOnLoad: true }});</script>
</body></html>"""
    with open(OUT_HTML, "w", encoding="utf-8") as f:
        f.write(html)

    t5 = time.perf_counter()
    write_json_outputs(maps, meta_idx)
    timings.append(("write_json_outputs", time.perf_counter() - t5))
    with open(OUT_TEST_COVERAGE_JSON, "w", encoding="utf-8") as f:
        json.dump(test_cov, f, indent=2)
    total = sum(d for _, d in timings)
    if args.profile:
        print("PROFILE (coverage_map.py stage timings, seconds):")
        for name, dur in timings:
            print(f"  {name:30s} {dur:.4f}")
        print(f"  {'total':30s} {total:.4f}")
        # Quick heuristic bottleneck hints
        slow = [n for n, d in timings if d / total > 0.25]
        if slow:
            print("Bottleneck candidates (>25%):", ", ".join(slow))
            print(
                "Hints: cache YAML loads (reuse tools.lib.metadata_loader), batch filesystem existence checks, "
                "and persist path_status between runs."
            )
    else:
        print(
            "Wrote:",
            OUT_MD,
            OUT_HTML,
            OUT_INDEX_JSON,
            OUT_COVERAGE_JSON,
            OUT_PLUGIN_INDEX_JSON,
            OUT_POLICIES_CSV,
        )


if __name__ == "__main__":
    main()
