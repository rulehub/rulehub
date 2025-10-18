#!/usr/bin/env python3
"""
Export minimal metadata for the Backstage plugin index merge.

Produces dist/plugin-index-metadata.json with shape:
{
  "packages": [
    {
      "id": "<rulehub id>",
      "name": "<display name>",           # optional; fallback to id in UI if absent
      "standard": "<Standard name>",      # e.g., "PCI DSS 4.0"
      "version": "<version>",             # e.g., "current" or "4.0"
      "jurisdiction": ["Global", ...],    # optional list of areas
      "coverage": ["PCI DSS 4.0", ...]    # optional list based on compliance maps
    }
  ]
}

Notes:
 - Keep fields optional; the charts generator merges only present keys.
 - Deterministic ordering by id.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Dict, List, Mapping, Optional, Set, cast

import yaml


ROOT = Path(__file__).resolve().parents[1]
POLICIES_DIR = ROOT / "policies"
COMPLIANCE_MAPS_DIR = ROOT / "compliance" / "maps"
OUT_DIR = ROOT / "dist"
OUT_FILE = OUT_DIR / "plugin-index-metadata.json"


def _iter_policy_metadata(paths_root: Path) -> List[Path]:
    return sorted(paths_root.glob("**/metadata.yaml"))


def _load_yaml(p: Path) -> Any:
    with p.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def _fmt_coverage(regulation: str | None, version: str | None) -> str | None:
    if not regulation:
        return None
    if version and str(version).strip():
        return f"{regulation} {version}"
    return regulation


def _collect_compliance_coverage(maps_root: Path) -> Dict[str, Set[str]]:
    coverage: Dict[str, Set[str]] = {}
    for yml in sorted(maps_root.glob("*.yml")):
        try:
            data = _load_yaml(yml)
        except Exception:
            continue
        if not isinstance(data, dict):
            continue
        data_d = cast(Dict[str, Any], data)
        regulation = cast(Optional[str], data_d.get("regulation"))
        version = cast(Optional[str], data_d.get("version"))
        cov_label = _fmt_coverage(regulation, version)
        if not cov_label:
            continue
        sections = data_d.get("sections")
        if isinstance(sections, dict):
            sections_d = cast(Dict[str, Any], sections)
            for sec_val in sections_d.values():
                policies: List[Any] | None = None
                if isinstance(sec_val, dict):
                    sec_d = cast(Dict[str, Any], sec_val)
                    pol = cast(Optional[List[Any]], sec_d.get("policies"))
                    if isinstance(pol, list):
                        policies = pol
                if policies is None:
                    continue
                for pid in policies:
                    if not isinstance(pid, str):
                        continue
                    coverage.setdefault(pid, set()).add(cov_label)
    return coverage


def _first_str(x: Any) -> str | None:
    return str(x) if x is not None else None


def _extract_jurisdiction(meta: Mapping[str, Any]) -> List[str] | None:
    # Prefer explicit jurisdiction list if present
    j: Any = meta.get("jurisdiction")
    if isinstance(j, list):
        vals = [str(v) for v in j if v is not None]
        return vals or None
    if isinstance(j, str) and j.strip():
        return [j]
    # Fallback to geo.scope/regions if available
    geo_raw: Any = meta.get("geo")
    geo: Optional[Dict[str, Any]] = geo_raw if isinstance(geo_raw, dict) else None  # type: ignore[assignment]
    if geo is not None:
        scope: Any = geo.get("scope")
        regions_raw: Any = geo.get("regions")
        regions: Optional[List[Any]] = regions_raw if isinstance(regions_raw, list) else None  # type: ignore[assignment]
        if regions:
            vals = [str(v) for v in regions if v is not None]
            return vals or None
        if scope:
            return [str(scope)]
    return None


def _extract_industry(meta: Mapping[str, Any]) -> Any:
    """Return industry field as-is if provided in metadata.

    Accepts either a string (e.g., "fintech") or a list of strings (e.g., ["fintech", "gaming"]).
    Filters out falsy entries in lists and normalizes items to strings.
    Returns None if not present or empty.
    """
    ind: Any = meta.get("industry")
    if isinstance(ind, list):
        vals = [str(v).strip() for v in ind if v]
        return vals or None
    if isinstance(ind, str):
        s = ind.strip()
        return s or None
    return None


def _derive_industry_from_domain(pid: str) -> Any:
    """Derive industry from the policy id domain prefix when not explicitly provided.

    Returns either a string (e.g., "medtech") or a list of strings (e.g., ["fintech", "banking"]).
    Deterministic mapping; extend cautiously to avoid breaking filters.
    """
    try:
        domain, _ = pid.split(".", 1)
    except ValueError:
        domain = pid
    d = domain.lower().strip()
    mapping: Dict[str, Any] = {
        "aml": ["fintech", "banking"],
        "betting": "gambling",
        "igaming": "gambling",
        "rg": "gambling",
        "edtech": "edtech",
        "medtech": "medtech",
        "legaltech": "legaltech",
        "fintech": "fintech",
        "pci": "payments",
        "gdpr": "privacy",
        "k8s": "platform",
    }
    return mapping.get(d)


def _format_industry_display(val: Any) -> Any:
    """Format industry value(s) for display: apply canonical casing/mapping.

    - Accepts string or list of strings; returns same shape with formatted labels.
    - Known mappings: fintech->FinTech, medtech->MedTech, igaming->iGaming, edtech->EdTech,
      legaltech->LegalTech, gambling->Gambling, banking->Banking, payments->Payments,
      privacy->Privacy, platform->Platform.
    - Unknown values fall back to Title Case by token (non-alnum split).
    """
    def _fmt_one(s: str) -> str:
        raw = (s or "").strip()
        k = raw.lower()
        mapping = {
            "fintech": "FinTech",
            "medtech": "MedTech",
            "igaming": "iGaming",
            "edtech": "EdTech",
            "legaltech": "LegalTech",
            "gambling": "Gambling",
            "banking": "Banking",
            "payments": "Payments",
            "privacy": "Privacy",
            "platform": "Platform",
        }
        if k in mapping:
            return mapping[k]
        # Generic title case fallback
        parts = [p for p in re.split(r"[^A-Za-z0-9]+", raw) if p]
        return " ".join(p[:1].upper() + p[1:] for p in parts) if parts else raw

    if isinstance(val, list):
        seq: List[Any] = val
        out: List[str] = [_fmt_one(str(x)) for x in seq if x is not None]
        # preserve shape; de-dup while keeping order
        seen: Set[str] = set()
        dedup: List[str] = []
        for v in out:
            if v not in seen:
                seen.add(v)
                dedup.append(v)
        return dedup
    if isinstance(val, str):
        return _fmt_one(val)
    return val


_PLACEHOLDER_RE = re.compile(r"^\s*$|^<[^>]*>$|^n/?a$|^unknown$", re.IGNORECASE)


def _is_placeholder(val: Any) -> bool:
    if val is None:
        return True
    s = str(val).strip()
    return bool(_PLACEHOLDER_RE.search(s))


def _humanize_name(pid: str, fallback: str | None) -> str | None:
    if fallback and not _is_placeholder(fallback) and fallback != pid:
        return fallback
    try:
        _, short = pid.split(".", 1)
    except ValueError:
        short = pid
    tokens = [t for t in re.split(r"[_\-/]+", short) if t]
    acr = {"api", "uk", "us", "eu", "gdpr", "hipaa", "pci", "kyc", "aml", "mfa", "sbom", "fhir", "onc"}
    words: List[str] = []
    for t in tokens:
        words.append(t.upper() if t.lower() in acr else t.capitalize())
    name = " ".join(words)
    return name or fallback or pid


def _derive_standard_version(pid: str, std: Any, ver: Any) -> tuple[str | None, str | None]:
    # If values are not placeholders, return as-is
    if not _is_placeholder(std) and not _is_placeholder(ver):
        return (_first_str(std), _first_str(ver))
    try:
        domain, short = pid.split(".", 1)
    except ValueError:
        domain, short = pid, ""
    s = short.lower()
    if domain == "gdpr" or "gdpr" in s:
        return ("GDPR", "2016/679")
    if domain == "pci" or "pci_" in s:
        return ("PCI DSS", "4.0")
    if domain == "k8s" or (isinstance(std, str) and "kubernetes" in std.lower()):
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
        if "pdpa_sg" in s or ("pdpa" in s and "sg" in s):
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
    # Generic fallback: avoid placeholders
    std_s = _first_str(std)
    ver_s = _first_str(ver)
    if _is_placeholder(std_s):
        std_s = domain.upper()
    if _is_placeholder(ver_s):
        ver_s = "current"
    return (std_s, ver_s)


def build_packages(
    policies_root: Path = POLICIES_DIR, maps_root: Path = COMPLIANCE_MAPS_DIR
) -> Dict[str, Any]:
    coverage_map = _collect_compliance_coverage(maps_root)

    pkgs: Dict[str, Dict[str, Any]] = {}
    for meta_path in _iter_policy_metadata(policies_root):
        try:
            meta_any = _load_yaml(meta_path)
        except Exception:
            continue
        if not isinstance(meta_any, dict):
            continue
        meta = cast(Dict[str, Any], meta_any)
        pid = _first_str(meta.get("id"))
        if not pid:
            continue
        name = _first_str(meta.get("name"))
        std_raw = meta.get("standard")
        standard_name: str | None = None
        standard_version: str | None = None
        if isinstance(std_raw, dict):
            std_d = cast(Dict[str, Any], std_raw)
            standard_name = _first_str(std_d.get("name"))
            standard_version = _first_str(std_d.get("version"))
        elif isinstance(std_raw, str):
            standard_name = std_raw
            # Some legacy metadata stores version at top-level when standard is a string
            standard_version = _first_str(meta.get("version"))
        else:
            standard_name = None
            standard_version = _first_str(meta.get("version"))

        # Apply placeholder cleanup/derivation for name/standard/version
        name = _humanize_name(pid, name)
        derived_std, derived_ver = _derive_standard_version(pid, standard_name, standard_version)
        standard_name = derived_std
        standard_version = derived_ver

        jurisdiction = _extract_jurisdiction(meta)
        industry = _extract_industry(meta)

        pkg: Dict[str, Any] = {"id": pid}
        if name and name != pid:
            pkg["name"] = name
        if standard_name:
            pkg["standard"] = standard_name
        if standard_version:
            pkg["version"] = standard_version
        if jurisdiction:
            pkg["jurisdiction"] = jurisdiction
        if industry is not None:
            pkg["industry"] = _format_industry_display(industry)
        else:
            derived_ind = _derive_industry_from_domain(pid)
            if derived_ind is not None:
                pkg["industry"] = _format_industry_display(derived_ind)

        cov = sorted(coverage_map.get(pid, set()))
        if cov:
            pkg["coverage"] = cov

        pkgs[pid] = pkg

    packages_sorted = [pkgs[k] for k in sorted(pkgs.keys())]
    return {"packages": packages_sorted}


def main() -> None:
    data = build_packages()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    tmp = OUT_FILE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    # Minimize churn
    if OUT_FILE.exists() and OUT_FILE.read_text(encoding="utf-8") == tmp.read_text(encoding="utf-8"):
        tmp.unlink(missing_ok=True)
        print(f"{OUT_FILE} unchanged")
        return
    tmp.replace(OUT_FILE)
    print(f"Wrote {OUT_FILE}")


if __name__ == "__main__":
    main()
