#!/usr/bin/env python3
"""Compare policy metadata (policies/**/metadata.yaml) against local template
annotations under addons/**/templates and templates/.

Outputs divergences as: File | Field | Expected | Actual
"""

from __future__ import annotations

from pathlib import Path
from typing import Dict, List

import yaml


ROOT = Path(__file__).resolve().parents[1]


def load_metadata() -> Dict[str, Dict]:
    out: Dict[str, Dict] = {}
    for meta in (ROOT / "policies").rglob("metadata.yaml"):
        try:
            data = yaml.safe_load(meta.read_text(encoding="utf-8")) or {}
        except Exception:
            continue
        if not isinstance(data, dict):
            continue
        pid = data.get("id")
        if not pid:
            # fallback to folder name
            pid = meta.parent.name
        out[str(pid)] = {
            "name": data.get("name") or data.get("title") or "",
            "links": data.get("links") or [],
            "meta_path": str(meta),
        }
    return out


def iter_yaml_documents(path: Path):
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return
    try:
        for d in yaml.safe_load_all(text):
            if isinstance(d, dict):
                yield d
    except yaml.YAMLError:
        return


def extract_annotations_from_file(path: Path) -> List[Dict]:
    res: List[Dict] = []
    for doc in iter_yaml_documents(path):
        meta = doc.get("metadata") if isinstance(doc, dict) else None
        if not isinstance(meta, dict):
            continue
        ann = meta.get("annotations") or {}
        labels = meta.get("labels") or {}
        # prefer annotations, but allow labels
        rid = ann.get("rulehub.id") or labels.get("rulehub.id")
        if not rid:
            continue
        title = ann.get("rulehub.title") or labels.get("rulehub.title") or ""
        links_raw = ann.get("rulehub.links") or labels.get("rulehub.links") or ""
        links = []
        if isinstance(links_raw, list):
            links = links_raw
        elif isinstance(links_raw, str):
            # split lines and strip common list markup
            for ln in links_raw.splitlines():
                ln = ln.strip()
                if ln.startswith("- "):
                    ln = ln[2:].strip()
                # remove surrounding <> if present
                if ln.startswith("<") and ln.endswith(">"):
                    ln = ln[1:-1]
                if ln:
                    links.append(ln)
        res.append(
            {
                "id": str(rid).strip(),
                "title": str(title).strip(),
                "links": links,
                "file": str(path),
            }
        )
    return res


def gather_template_annotations() -> Dict[str, List[Dict]]:
    out: Dict[str, List[Dict]] = {}
    paths = list((ROOT / "addons").rglob("templates/*.yaml")) + list((ROOT / "templates").rglob("**/*.tmpl"))
    # also include addons kyverno policies which are templates too
    paths += list((ROOT / "addons").rglob("*.yaml"))
    seen = set()
    for p in paths:
        if not p.exists() or p.suffix.lower() not in (".yaml", ".yml", ".tmpl"):
            continue
        if str(p) in seen:
            continue
        seen.add(str(p))
        anns = extract_annotations_from_file(p)
        for a in anns:
            out.setdefault(a["id"], []).append(a)
    return out


def normalize_links(links) -> List[str]:
    if links is None:
        return []
    out: List[str] = []
    for link in links:
        if not isinstance(link, str):
            continue
        s = link.strip()
        if s.startswith("<") and s.endswith(">"):
            s = s[1:-1]
        out.append(s)
    return out


def main():
    meta = load_metadata()
    templates = gather_template_annotations()

    divergences: List[Dict] = []

    # For each metadata entry, compare against templates with same id
    for pid, info in meta.items():
        expected_title = (info.get("name") or "").strip()
        expected_links = normalize_links(info.get("links") or [])
        tpl_entries = templates.get(pid) or []
        if not tpl_entries:
            divergences.append(
                {
                    "file": "(none)",
                    "id": pid,
                    "field": "file",
                    "expected": "template with rulehub.id",
                    "actual": "missing",
                }
            )
            continue
        for te in tpl_entries:
            actual_title = (te.get("title") or "").strip()
            actual_links = normalize_links(te.get("links") or [])
            if expected_title != actual_title:
                divergences.append(
                    {
                        "file": te.get("file"),
                        "id": pid,
                        "field": "rulehub.title",
                        "expected": expected_title,
                        "actual": actual_title,
                    }
                )
            # compare links as sets to tolerate order
            if set(expected_links) != set(actual_links):
                divergences.append(
                    {
                        "file": te.get("file"),
                        "id": pid,
                        "field": "rulehub.links",
                        "expected": expected_links,
                        "actual": actual_links,
                    }
                )

    # Also detect templates that have rulehub.id but no metadata entry
    for tid, entries in templates.items():
        if tid not in meta:
            for te in entries:
                divergences.append(
                    {
                        "file": te.get("file"),
                        "id": tid,
                        "field": "metadata",
                        "expected": "metadata for id present in policies/",
                        "actual": "missing",
                    }
                )

    # Print report
    if not divergences:
        print("No divergences found")
        return 0

    print("File | ID | Field | Expected | Actual")
    for d in divergences:
        exp = d.get("expected")
        act = d.get("actual")
        # represent lists nicely
        if isinstance(exp, list):
            exp = "; ".join(exp)
        if isinstance(act, list):
            act = "; ".join(act)
        print(f"{d.get('file')} | {d.get('id')} | {d.get('field')} | {exp} | {act}")

    # Suggest commit message
    print("\nSuggested commit message:")
    print("fix(helm-templates): align rulehub.* annotations with policy metadata")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
