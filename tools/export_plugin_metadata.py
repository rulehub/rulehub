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
from pathlib import Path
from typing import Any, Dict, List, Mapping, Set

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
        regulation = data.get("regulation")  # type: ignore[assignment]
        version = data.get("version")  # type: ignore[assignment]
        cov_label = _fmt_coverage(regulation, version)
        if not cov_label:
            continue
        sections = data.get("sections") or {}
        if isinstance(sections, dict):
            for sec in sections.values():
                policies = []
                if isinstance(sec, dict):
                    policies = sec.get("policies") or []
                if isinstance(policies, list):
                    for pid in policies:
                        if not isinstance(pid, str):
                            continue
                        coverage.setdefault(pid, set()).add(cov_label)
    return coverage


def _first_str(x: Any) -> str | None:
    return str(x) if x is not None else None


def _extract_jurisdiction(meta: Mapping[str, Any]) -> List[str] | None:
    # Prefer explicit jurisdiction list if present
    j = meta.get("jurisdiction")
    if isinstance(j, list):
        vals = [str(v) for v in j if v is not None]
        return vals or None
    if isinstance(j, str) and j.strip():
        return [j]
    # Fallback to geo.scope/regions if available
    geo = meta.get("geo") or {}
    if isinstance(geo, dict):
        scope = geo.get("scope")
        regions = geo.get("regions") if isinstance(geo.get("regions"), list) else None
        if regions:
            vals = [str(v) for v in regions if v is not None]
            return vals or None
        if scope:
            return [str(scope)]
    return None


def build_packages(
    policies_root: Path = POLICIES_DIR, maps_root: Path = COMPLIANCE_MAPS_DIR
) -> Dict[str, Any]:
    coverage_map = _collect_compliance_coverage(maps_root)

    pkgs: Dict[str, Dict[str, Any]] = {}
    for meta_path in _iter_policy_metadata(policies_root):
        try:
            meta = _load_yaml(meta_path)
        except Exception:
            continue
        if not isinstance(meta, dict):
            continue
        pid = _first_str(meta.get("id"))
        if not pid:
            continue
        name = _first_str(meta.get("name"))
        std_raw = meta.get("standard")
        standard_name: str | None = None
        standard_version: str | None = None
        if isinstance(std_raw, dict):
            standard_name = _first_str(std_raw.get("name"))
            standard_version = _first_str(std_raw.get("version"))
        elif isinstance(std_raw, str):
            standard_name = std_raw
            # Some legacy metadata stores version at top-level when standard is a string
            standard_version = _first_str(meta.get("version"))
        else:
            standard_name = None
            standard_version = _first_str(meta.get("version"))

        jurisdiction = _extract_jurisdiction(meta)

        pkg: Dict[str, Any] = {"id": pid}
        if name and name != pid:
            pkg["name"] = name
        if standard_name:
            pkg["standard"] = standard_name
        if standard_version:
            pkg["version"] = standard_version
        if jurisdiction:
            pkg["jurisdiction"] = jurisdiction

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
