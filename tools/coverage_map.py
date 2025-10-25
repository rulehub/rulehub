#!/usr/bin/env python3
import argparse
import csv
import json
import os
import re
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

# Default base URL for generating web links to repository files. Can be overridden via
# environment variable RULEHUB_REPO_URL_BASE to point at a different host/branch.
REPO_URL_BASE_DEFAULT = "https://github.com/rulehub/rulehub/blob/main/"


def _repo_url_for(rel_path: str) -> str:
    base = os.environ.get("RULEHUB_REPO_URL_BASE", REPO_URL_BASE_DEFAULT)
    base = base if base.endswith("/") else base + "/"
    return f"{base}{rel_path.lstrip('/')}"


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
                short_id = parts[pol_idx +
                                 2] if len(parts) > pol_idx + 2 else None
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
        std_ver = std.get("version") if isinstance(
            std, dict) else y.get("version")
        # Record repo-relative directory of the policy to enable URLs/paths later
        policy_dir = str(meta.parent)
        # jurisdiction: prefer explicit; otherwise derive from geo (scope or regions)
        jurisdiction = y.get("jurisdiction")
        if not jurisdiction:
            geo = y.get("geo") or {}
            scope = geo.get("scope") if isinstance(geo, dict) else None
            regions = geo.get("regions") if isinstance(geo, dict) else None
            if scope and isinstance(scope, str) and scope.strip():
                jurisdiction = [scope.strip()]
            elif regions and isinstance(regions, list) and regions:
                # Normalize to unique list of strings
                jurisdiction = [str(r).strip() for r in regions if str(r).strip()]
            else:
                jurisdiction = None

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
            "jurisdiction": jurisdiction,
            "_policy_dir": policy_dir,
        }
    return idx


def load_mappings():
    maps = []
    # Deterministic order: sort files by path
    for mp in sorted(MAPS_DIR.glob("*.yml")):
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
            cov = "OK" if all(
                pid in meta_idx for pid in pols) and pols else "WARN"
            if pols:
                covered += sum(1 for pid in pols if pid in meta_idx)
                total += len(pols)
            # path icons for each policy id (reuse cached exists)

            def _path_icons(pid: str) -> str:
                paths = (meta_idx.get(pid) or {}).get("path") or []
                if not paths:
                    return f"{pid}: —"
                parts = [("OK" if _path_exists(p) else "MISS") +
                         " " + p for p in paths]
                return f"{pid}: " + ", ".join(parts)

            path_counts = "; ".join(_path_icons(pid)
                                    for pid in pols) if pols else ""
            lines.append(
                f"| `{sec}` | {data.get('title', '')} | {', '.join(pols)} | {cov} | {path_counts} |")
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
        result[pid] = [{"path": p, "exists": bool(
            _path_exists(p))} for p in paths]
    return result


def build_policies_index(meta_idx, path_status):
    """Return list of policy objects for OUT_INDEX_JSON (no sorting to preserve current order)."""
    policies = []
    # Deterministic order: iterate by sorted policy id
    for pid in sorted(meta_idx.keys()):
        meta = meta_idx[pid]
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
                # In-repo Rego-backed policies (policy.rego) imply Gatekeeper framework
                if p.endswith("policy.rego") or p.endswith(".rego"):
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
            # Heuristic: constraints -> high; otherwise default medium for Rego-backed policies
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
    pmap = {p.get("id"): p for p in policies if isinstance(p, dict)}
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
                regions = ";".join((geo.get("regions") or [])
                                   if isinstance(geo, dict) else [])
                paths = p.get("paths") or []
                flat_paths_list = [str(x.get("path")) for x in paths if isinstance(
                    x, dict) and x.get("path")]
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

    # Helpers for sanitization and heuristic defaults
    placeholder_re = re.compile(r"^\s*$|^<[^>]*>$|^(?i:n/?a|unknown)$")

    def is_placeholder(val: Any) -> bool:
        if val is None:
            return True
        s = str(val).strip()
        return bool(placeholder_re.search(s))

    def humanize_name(pid: str) -> str:
        try:
            domain, short = pid.split(".", 1)
        except ValueError:
            short = pid
        # Replace underscores with spaces and title-case, preserve common acronyms
        tokens = [t for t in re.split(r"[_\-/]+", short) if t]
        acronyms = {"api", "uk", "us", "eu", "gdpr", "hipaa", "pci", "kyc", "aml", "mfa", "sbom", "fhir", "onC"}
        words: list[str] = []
        for t in tokens:
            tt = t.upper() if t.lower() in acronyms else (t.capitalize())
            words.append(tt)
        name = " ".join(words)
        return name or pid

    def derive_standard_version(pid: str, std: Any, ver: Any) -> tuple[str, str]:
        # If already non-placeholder values are present, preserve them
        if not is_placeholder(std) and not is_placeholder(ver):
            return str(std), str(ver)
        try:
            domain, short = pid.split(".", 1)
        except ValueError:
            domain, short = pid, ""
        s = short.lower()
        # Domain/token specific mappings
        if domain == "gdpr" or "gdpr" in s:
            return ("GDPR", "2016/679")
        if domain == "pci" or "pci_" in s:
            return ("PCI DSS", "4.0")
        if domain == "k8s" or "kubernetes" in (str(std or "").lower()):
            return ("Kubernetes", "1.x")
        if domain == "aml" or "aml" in s:
            return ("EU AMLD", "5/6")
        if domain == "fintech":
            if "psd2" in s:
                return ("PSD2", "2015/2366")
            if "ob_" in s or "open_banking" in s:
                return ("Open Banking (UK)", "current")
            if "fapi" in s:
                return ("FAPI", "current")
            # fallthrough to PCI/AML handled above if present in id
        if domain == "medtech":
            if "iso_27001" in s:
                return ("ISO/IEC 27001", "2022")
            if "iso_14971" in s:
                return ("ISO 14971", "2019")
            if "iso_13485" in s:
                return ("ISO 13485", "2016")
            if "iec_62304" in s:
                return ("IEC 62304", "2006")
            if "iec_62366" in s:
                return ("IEC 62366-1", "2015")
            if "eu_mdr" in s:
                return ("EU MDR", "2017/745")
            if "eu_ivdr" in s:
                return ("EU IVDR", "2017/746")
            if "hipaa" in s:
                return ("HIPAA", "Security Rule")
            if "hitech" in s:
                return ("HITECH Act", "2009")
            if "onc_" in s:
                return ("ONC Cures Act", "Cures Update")
            if "dicom" in s:
                return ("DICOM", "current")
            if "uk_dtac" in s:
                return ("NHS DTAC", "current")
        if domain == "legaltech":
            if "ccpa" in s and "cpra" in s:
                return ("CCPA/CPRA", "current")
            if "cpra" in s:
                return ("CPRA", "current")
            if "ccpa" in s:
                return ("CCPA", "current")
            if "pdpa_sg" in s or "pdpa" in s and "sg" in s:
                return ("PDPA (Singapore)", "current")
            if "pipl_cn" in s or ("pipl" in s and "cn" in s):
                return ("PIPL (China)", "current")
            if "app" in s and ("au_" in s or "australia" in s):
                return ("Australian Privacy Act (APPs)", "current")
            if "law25" in s:
                return ("Quebec Law 25", "current")
            if "lgpd" in s:
                return ("LGPD (Brazil)", "current")
            if "pdpl" in s:
                return ("PDPL (UAE)", "current")
            if "kvkk" in s:
                return ("KVKK (Turkey)", "current")
            if "pipeda" in s:
                return ("PIPEDA (Canada)", "current")
            if "fadp" in s:
                return ("FADP (Switzerland)", "current")
        if domain == "edtech":
            if "ferpa" in s:
                return ("FERPA", "current")
            if "coppa" in s:
                return ("COPPA", "current")
            if "ppra" in s:
                return ("PPRA", "current")
            if "edlaw2d" in s:
                return ("NY Education Law 2-d", "current")
            if "sopipa" in s:
                return ("SOPIPA (CA)", "current")
        # Generic fallback: use domain name as standard, current version
        return (domain.upper(), "current")

    def derive_owner(pid: str) -> str:
        # Map by top-level domain
        try:
            domain, _ = pid.split(".", 1)
        except ValueError:
            domain = pid
        mapping = {
            "k8s": "platform-security",
            "aml": "compliance",
            "fintech": "compliance",
            "gdpr": "compliance",
            "legaltech": "compliance",
            "medtech": "compliance",
            "edtech": "compliance",
            "betting": "compliance",
            "rg": "compliance",
            "igaming": "compliance",
            "pci": "compliance",
        }
        return mapping.get(domain, "compliance")

    def derive_tags(pid: str, framework: str | None, std_name: str | None) -> list[str]:
        tags: list[str] = []
        # Domain tag
        try:
            domain, short = pid.split(".", 1)
        except ValueError:
            domain, short = pid, ""
        tags.append(domain.lower())
        # Framework/engine
        if framework == "kyverno":
            tags.extend(["kubernetes", "kyverno"])
        elif framework == "gatekeeper":
            # Rego-backed Gatekeeper policies (often cluster/K8s or generic)
            # Add kubernetes only for k8s domain to avoid misleading tags cross-domain
            if domain == "k8s":
                tags.append("kubernetes")
            tags.extend(["gatekeeper", "rego"])
        # Standard-derived tag (normalized slug)
        if isinstance(std_name, str) and std_name:
            s = std_name.lower()
            # prioritize common slugs
            if "gdpr" in s:
                tags.append("gdpr")
            elif "pci" in s:
                tags.append("pci")
            elif "hipaa" in s:
                tags.append("hipaa")
            elif "psd2" in s:
                tags.append("psd2")
            elif "open banking" in s:
                tags.append("open-banking")
            elif "fapi" in s:
                tags.append("fapi")
            elif "iso/iec 27001" in s or "iso 27001" in s:
                tags.append("iso-27001")
            elif "iso 13485" in s:
                tags.append("iso-13485")
            elif "iso 14971" in s:
                tags.append("iso-14971")
            elif "iec 62304" in s:
                tags.append("iec-62304")
            elif "iec 62366" in s:
                tags.append("iec-62366")
            elif "eu mdr" in s:
                tags.append("mdr")
            elif "eu ivdr" in s:
                tags.append("ivdr")
            elif "kubernetes" in s:
                tags.append("kubernetes")
        # Thematic hints from id short part
        ss = short.lower()
        if any(k in ss for k in ["aml", "sanctions", "pep", "kyc", "watchlist", "risk", "monitoring"]):
            tags.append("aml")
        if any(k in ss for k in ["auth", "mfa", "oauth", "jwt", "mtls", "3ds", "sca", "tpp"]):
            tags.append("security")
        if domain == "k8s":
            if any(k in ss for k in ["hostnetwork", "network"]):
                tags.append("network")
            if any(k in ss for k in ["hostpath", "storage", "volume"]):
                tags.append("storage")
            if any(k in ss for k in ["image", "supply", "pullpolicy", "latest"]):
                tags.append("supply-chain")
        # Deduplicate and sort for determinism
        uniq_sorted = sorted({t for t in tags if t})
        return uniq_sorted

    packages: list[dict[str, Any]] = []
    # Deterministic order: iterate by sorted policy id
    for pid in sorted(meta_idx.keys()):
        meta = meta_idx[pid]
        # Base required fields (sanitize placeholders with heuristics)
        std_val = meta.get("standard")
        ver_val = meta.get("version")
        std_val, ver_val = derive_standard_version(pid, std_val, ver_val)
        name_val = meta.get("name")
        if is_placeholder(name_val):
            name_val = humanize_name(pid)
        desc_val = meta.get("description")
        if is_placeholder(desc_val):
            desc_val = f"Policy: {name_val}."
        owner_val = meta.get("owner") or derive_owner(pid)
        pkg: dict[str, Any] = {
            "id": pid,
            "name": name_val,
            "standard": std_val,
            "version": ver_val,
            "coverage": coverage_by_policy.get(pid, []),
        }
        # Optional metadata fields (present in metadata.yaml or inferred)
        if meta.get("jurisdiction"):
            pkg["jurisdiction"] = meta.get("jurisdiction")
        if desc_val:
            pkg["description"] = desc_val
        # Owner: prefer metadata, else heuristic
        if owner_val:
            pkg["owner"] = owner_val
        # Determine framework prior to tag derivation (from policies index 'p')
        if meta.get("links"):
            pkg["links"] = meta.get("links")
        # Derived/enhanced fields from policies index
        p = pmap.get(pid) or {}
        if p.get("framework"):
            pkg["framework"] = p.get("framework")
        if p.get("severity"):
            pkg["severity"] = p.get("severity")
        if p.get("geo"):
            pkg["geo"] = p.get("geo")
        if p.get("paths"):
            pkg["paths"] = p.get("paths")

        # Repository path and URL: prefer the directory containing metadata.yaml if under policies/
        policy_dir = meta.get("_policy_dir") or ""
        if policy_dir and policy_dir.startswith("policies/"):
            pkg["repoPath"] = policy_dir
            pkg["repoUrl"] = _repo_url_for(policy_dir)
        else:
            # Fallback: attempt from the first path entry
            paths_list = p.get("paths") or []
            if paths_list:
                first_path = paths_list[0].get("path") if isinstance(paths_list[0], dict) else None
                if isinstance(first_path, str):
                    # Use the directory component for repoPath
                    repo_dir = str(Path(first_path).parent)
                    pkg["repoPath"] = repo_dir
                    pkg["repoUrl"] = _repo_url_for(repo_dir)

        # Engine-specific artifact links (paths + URLs) from discovered paths
        paths_entries = p.get("paths") or []
        kyv_items: list[dict[str, str]] = []
        gk_items: list[dict[str, str]] = []
        for pe in paths_entries:
            if not isinstance(pe, dict):
                continue
            rel = pe.get("path")
            if not isinstance(rel, str):
                continue
            # Kyverno YAMLs
            if (
                ("/kyverno/" in rel or rel.startswith("addons/kyverno"))
                and (rel.endswith(".yaml") or rel.endswith(".yml"))
            ):
                kyv_items.append({"path": rel, "url": _repo_url_for(rel)})
            # Gatekeeper Rego or templates/constraints YAMLs
            if (
                "k8s-gatekeeper" in rel
                or rel.endswith("policy.rego")
                or "/templates/" in rel
                or "/constraints/" in rel
            ):
                gk_items.append({"path": rel, "url": _repo_url_for(rel)})
        if kyv_items:
            pkg["kyverno"] = kyv_items
        if gk_items:
            pkg["gatekeeper"] = gk_items
        # Tags: prefer metadata; otherwise derive deterministically from id/framework/standard
        if meta.get("tags"):
            if isinstance(meta.get("tags"), list) and meta.get("tags"):
                pkg["tags"] = meta.get("tags")
        else:
            tgs = derive_tags(pid, pkg.get("framework"), std_val)
            if tgs:
                pkg["tags"] = tgs
        packages.append(pkg)

    # Allow forcing a specific schema version (future use) or disabling the new
    # field via env flags:
    #   RULEHUB_INDEX_SCHEMA_VERSION (int) -> overrides default
    #   RULEHUB_DISABLE_SCHEMA_VERSION=1   -> omit field for consumers expecting earlier output
    schema_version = int(os.environ.get(
        "RULEHUB_INDEX_SCHEMA_VERSION", str(SCHEMA_VERSION_DEFAULT)))
    disable_schema_flag = os.environ.get("RULEHUB_DISABLE_SCHEMA_VERSION", "0") in {
        "1", "true", "TRUE"}
    if disable_schema_flag:
        index_payload: dict[str, Any] = {"packages": packages}
    else:
        # Include schemaVersion for forward migration; consumers can opt out with env flag.
        index_payload = {"schemaVersion": schema_version, "packages": packages}
    with open(OUT_PLUGIN_INDEX_JSON, "w", encoding="utf-8") as f:
        json.dump(index_payload, f, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(
        description="Generate coverage & index artifacts")
    parser.add_argument("--profile", action="store_true",
                        help="Print timing breakdown stages")
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
