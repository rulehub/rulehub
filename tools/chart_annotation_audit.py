#!/usr/bin/env python3
"""Compare expected policy metadata annotations vs Helm chart templates.

Outputs divergences as: File | Field | Expected | Actual and writes a patch hint section.

Usage:
    tools/chart_annotation_audit.py --charts-dir <path>
    [--policies-root policies]
    [--out dist/integrity/helm_annotations.md]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any, Dict, Generator, List

import yaml


ROOT = Path(__file__).resolve().parents[1]


def load_metadata(policies_root: Path) -> Dict[str, Dict[str, Any]]:
    out: Dict[str, Dict[str, Any]] = {}
    for meta in (policies_root).rglob("metadata.yaml"):
        try:
            data = yaml.safe_load(meta.read_text(encoding="utf-8")) or {}
        except Exception:
            continue
        if not isinstance(data, dict):
            continue
        pid = data.get("id") or meta.parent.name
        out[str(pid)] = {
            "title": (data.get("name") or data.get("title") or "").strip(),
            "links": data.get("links") or [],
            "meta_path": str(meta),
        }
    return out


def iter_yaml_documents(path: Path) -> Generator[Dict[str, Any], None, None]:
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return
    try:
        for d in yaml.safe_load_all(text):
            if isinstance(d, dict):
                # Narrow type for downstream usage
                yield dict(d)
    except yaml.YAMLError:
        return


def extract_chart_annotations(charts_dir: Path) -> Dict[str, List[Dict[str, Any]]]:
    out: Dict[str, List[Dict[str, Any]]] = {}
    for yfile in charts_dir.rglob("*.y*ml"):
        for doc in iter_yaml_documents(yfile):
            meta = doc.get("metadata") if isinstance(doc, dict) else None
            if not isinstance(meta, dict):
                continue
            # prefer annotations, fall back to labels
            ann = meta.get("annotations") or {}
            labels = meta.get("labels") or {}
            rid = ann.get("rulehub.id") or labels.get("rulehub.id")
            if not rid:
                continue
            title = ann.get("rulehub.title") or labels.get(
                "rulehub.title") or ""
            links_raw = ann.get("rulehub.links") or labels.get(
                "rulehub.links") or ""
            links = []
            if isinstance(links_raw, list):
                links = links_raw
            elif isinstance(links_raw, str):
                for ln in links_raw.splitlines():
                    ln = ln.strip()
                    if ln.startswith("- "):
                        ln = ln[2:].strip()
                    if ln.startswith("<") and ln.endswith(">"):
                        ln = ln[1:-1]
                    if ln:
                        links.append(ln)
            out.setdefault(str(rid).strip(), []).append({
                "file": str(yfile),
                "title": str(title).strip(),
                "links": links,
            })
    return out


def normalize_links(links: Any) -> List[str]:
    if links is None:
        return []
    out: List[str] = []
    for item in links:
        if not isinstance(item, str):
            continue
        s = item.strip()
        if s.startswith("<") and s.endswith(">"):
            s = s[1:-1]
        out.append(s)
    return out


def write_report(out_path: Path, divergences: List[Dict[str, Any]]):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    lines: List[str] = []
    if not divergences:
        lines.append("No divergences found")
        out_path.write_text("\n".join(lines), encoding="utf-8")
        return

    lines.append("File | ID | Field | Expected | Actual")
    lines.append("--- | --- | --- | --- | ---")
    for d in divergences:
        exp = d.get("expected")
        act = d.get("actual")
        if isinstance(exp, list):
            exp = "; ".join(exp)
        if isinstance(act, list):
            act = "; ".join(act)
        lines.append(
            f"{d.get('file')} | {d.get('id')} | {d.get('field')} | {exp} | {act}"
        )

    lines.append("")
    lines.append("Patch hints:")
    for d in divergences:
        fid = d.get("file")
        field = d.get("field")
        idv = d.get("id")
        exp = d.get("expected")
        if isinstance(exp, list):
            exp = "; ".join(exp)
        # simple hint: set annotation in file
        if field == "rulehub.title":
            lines.append(
                (
                    f"- Update {fid}: set metadata.annotations.rulehub.title='{exp}' "
                    f"for id {idv}"
                )
            )
        elif field == "rulehub.links":
            lines.append(
                (
                    f"- Update {fid}: set metadata.annotations.rulehub.links "
                    f"to contain: {exp} for id {idv}"
                )
            )
        elif field == "file":
            lines.append(
                f"- Add a template in charts containing metadata.annotations.rulehub.id={idv}")
        else:
            lines.append(f"- Review {fid} for id {idv}: {field} mismatch")

    out_path.write_text("\n".join(lines), encoding="utf-8")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description="Audit Helm charts annotations vs policy metadata")
    ap.add_argument("--charts-dir", required=True,
                    help="Path to charts files directory")
    ap.add_argument("--policies-root", default=str(ROOT /
                    "policies"), help="Policies root dir")
    ap.add_argument(
        "--out",
        default=str(ROOT / "dist" / "integrity" / "helm_annotations.md"),
        help="Output report path",
    )
    args = ap.parse_args(argv)

    charts_dir = Path(args.charts_dir)
    if not charts_dir.exists():
        print(f"charts directory not found: {charts_dir}", file=sys.stderr)
        return 1

    policies_root = Path(args.policies_root)
    metadata = load_metadata(policies_root)
    chart_ann = extract_chart_annotations(charts_dir)

    divergences: List[Dict[str, Any]] = []

    # For each metadata entry, compare against chart annotations with same id
    for pid, info in metadata.items():
        expected_title = (info.get("title") or "").strip()
        expected_links = normalize_links(info.get("links") or [])
        entries = chart_ann.get(pid) or []
        if not entries:
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
        for e in entries:
            actual_title = (e.get("title") or "").strip()
            actual_links = normalize_links(e.get("links") or [])
            if expected_title != actual_title:
                divergences.append(
                    {
                        "file": e.get("file"),
                        "id": pid,
                        "field": "rulehub.title",
                        "expected": expected_title,
                        "actual": actual_title,
                    }
                )
            if set(expected_links) != set(actual_links):
                divergences.append(
                    {
                        "file": e.get("file"),
                        "id": pid,
                        "field": "rulehub.links",
                        "expected": expected_links,
                        "actual": actual_links,
                    }
                )

    # Detect chart entries without metadata
    for cid, entries in chart_ann.items():
        if cid not in metadata:
            for e in entries:
                divergences.append(
                    {
                        "file": e.get("file"),
                        "id": cid,
                        "field": "metadata",
                        "expected": "metadata for id present in policies/",
                        "actual": "missing",
                    }
                )

    write_report(Path(args.out), divergences)

    if not divergences:
        print("No divergences found")
    else:
        print(f"Wrote {args.out} with {len(divergences)} divergence(s)")

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
