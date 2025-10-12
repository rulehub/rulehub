#!/usr/bin/env python3
"""Backfill selected fields into policies/**/metadata.yaml deterministically.

Option B: write owner, tags, and jurisdiction into source metadata files while:
 - preserving existing non-empty values (do not overwrite)
 - deriving values with the same stable heuristics used by the generator
 - producing minimal diffs and preserving YAML formatting/comments

By default runs in dry-run mode. Use --write to apply changes.

Exit codes: 0 success; 1 error.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any, Iterable, cast

from ruamel.yaml import YAML


POLICY_ROOT = Path("policies")


def normalize_paths(p: str | Iterable[str] | None) -> list[str]:
    if p is None:
        return []
    if isinstance(p, str):
        return [p]
    if isinstance(p, (list, tuple)):
        return [str(x) for x in p]
    return []


def derive_owner(pid: str) -> str:
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


def infer_framework_from_paths(paths: list[str]) -> str | None:
    for p in paths:
        if "/kyverno/" in p or p.startswith("addons/kyverno"):
            return "kyverno"
        if "k8s-gatekeeper" in p or p.startswith("addons/k8s-gatekeeper"):
            return "gatekeeper"
        if p.endswith("policy.rego") or p.endswith(".rego"):
            return "gatekeeper"
    return None


def derive_tags(pid: str, framework: str | None, std_name: str | None) -> list[str]:
    tags: list[str] = []
    try:
        domain, short = pid.split(".", 1)
    except ValueError:
        domain, short = pid, ""
    tags.append(domain.lower())
    if framework == "kyverno":
        tags.extend(["kubernetes", "kyverno"])
    elif framework == "gatekeeper":
        if domain == "k8s":
            tags.append("kubernetes")
        tags.extend(["gatekeeper", "rego"])
    if isinstance(std_name, str) and std_name:
        s = std_name.lower()
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
    return sorted({t for t in tags if t})


def derive_jurisdiction(data: dict[str, Any]) -> list[str] | None:
    if "jurisdiction" in data and data.get("jurisdiction"):
        return None  # preserve existing
    geo_obj = data.get("geo") or {}
    if isinstance(geo_obj, dict):
        geo = cast(dict[str, Any], geo_obj)
        scope = geo.get("scope")
        regions = geo.get("regions")
        if isinstance(scope, str) and scope.strip():
            return [scope.strip()]
        if isinstance(regions, list) and regions:
            out: list[str] = []
            for r in regions:
                s = str(r).strip()
                if s:
                    out.append(s)
            return out if out else None
    return None


def backfill_one(meta_path: Path, yaml: YAML, write: bool = False) -> tuple[bool, dict[str, Any]]:
    loaded = yaml.load(meta_path.read_text(encoding="utf-8"))
    data: dict[str, Any] = loaded if isinstance(loaded, dict) else {}
    changed = False

    pid = data.get("id")
    if not isinstance(pid, str) or not pid:
        return False, {}
    path_val = data.get("path") if isinstance(data, dict) else None
    paths = normalize_paths(cast(Any, path_val))
    framework = infer_framework_from_paths(paths)
    std_name = None
    std_val = data.get("standard")
    if isinstance(std_val, dict):
        std_name = std_val.get("name")
    elif isinstance(std_val, str):
        std_name = std_val

    # owner
    if not data.get("owner"):
        data["owner"] = derive_owner(pid)
        changed = True

    # tags
    tags_val = data.get("tags")
    if not isinstance(tags_val, list) or len(tags_val) == 0:
        data["tags"] = derive_tags(pid, framework, std_name)
        changed = True

    # jurisdiction
    j = derive_jurisdiction(data)
    if j:
        data["jurisdiction"] = j
        changed = True

    if changed and write:
        with open(meta_path, "w", encoding="utf-8") as fh:
            yaml.dump(data, fh)

    return changed, {"owner": data.get("owner"), "tags": data.get("tags"), "jurisdiction": data.get("jurisdiction")}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Backfill owner/tags/jurisdiction into metadata.yaml deterministically"
    )
    parser.add_argument("--write", action="store_true", help="Apply changes (default: dry-run)")
    parser.add_argument("--root", type=Path, default=POLICY_ROOT, help="Policies root (default: policies)")
    args = parser.parse_args(argv)

    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.indent(mapping=2, sequence=2, offset=0)

    root = args.root
    if not root.exists():
        print(f"Policies root not found: {root}")
        return 1

    total = 0
    changed_count = 0
    for meta in root.glob("**/metadata.yaml"):
        total += 1
        try:
            changed, info = backfill_one(meta, yaml, write=args.write)
        except Exception as e:
            print(f"ERROR processing {meta}: {e}")
            return 1
        if changed:
            changed_count += 1
            print(
                "Updated {meta}: owner={owner} tags={tags} jurisdiction={jurisdiction}".format(
                    meta=meta,
                    owner=info.get("owner"),
                    tags=info.get("tags"),
                    jurisdiction=info.get("jurisdiction"),
                )
            )

    mode = "write" if args.write else "dry-run"
    print(f"Backfill complete ({mode}). Examined {total} file(s); updated {changed_count}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
