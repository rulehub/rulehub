#!/usr/bin/env python3
"""Produce a readiness report (Markdown + JSON) for RuleHub.

This is a lightweight, dependency-free implementation intended for CI use.

Usage: python -m tools.release.readiness_report --root <repo_root> --out-dir <dist/release>
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


def run_git(args: List[str], cwd: Path) -> str:
    try:
        out = subprocess.check_output(["git"] + args, cwd=str(cwd), stderr=subprocess.DEVNULL)
        return out.decode().strip()
    except Exception:
        return ""


def find_latest_tag_vs_head(root: Path) -> Dict[str, Any]:
    git_root = root
    tag = run_git(["describe", "--tags", "--abbrev=0"], git_root)
    head = run_git(["rev-parse", "HEAD"], git_root)
    commits = run_git(["log", "--oneline", f"{tag}..{head}", "--"], git_root)
    return {
        "latest_tag": tag or "N/A",
        "head": head or "N/A",
        "commits_since_tag": commits.splitlines() if commits else [],
    }


def read_file_if_exists(path: Path) -> Optional[str]:
    if path.exists():
        try:
            return path.read_text()
        except Exception:
            return None
    return None


def changelog_diff(root: Path, tag: str) -> List[str]:
    # Simple heuristic: extract unreleased section from CHANGELOG.md
    changelog = read_file_if_exists(root / "CHANGELOG.md")
    if not changelog:
        return []
    # look for headings after the tag name or 'Unreleased'
    lines = changelog.splitlines()
    collecting = False
    collected: List[str] = []
    for ln in lines:
        if re.match(r"^##?\s+\[?Unreleased\]?", ln, re.I) or (tag != "" and tag != "N/A" and tag in ln):
            collecting = True
            continue
        if collecting and re.match(r"^##?\s+", ln):
            break
        if collecting:
            collected.append(ln)
    # fallback: show last 30 lines
    if not collected:
        return lines[-30:]
    return collected


def scan_for_todos(root: Path) -> List[Dict[str, Any]]:
    findings: List[Dict[str, Any]] = []
    patterns = [r"TODO", r"FIXME", r"DEBUG"]
    for p in root.rglob("*.py"):
        try:
            text = p.read_text()
        except Exception:
            continue
        for i, ln in enumerate(text.splitlines(), start=1):
            for pat in patterns:
                if pat in ln:
                    findings.append({"file": str(p.relative_to(root)), "line": i, "snippet": ln.strip(), "tag": pat})
    return findings


def collect_link_issues(root: Path) -> List[Dict[str, Any]]:
    # Look for links_audit*.json in repo root
    out: List[Dict[str, Any]] = []
    for p in root.glob("links_audit*.json"):
        try:
            j = json.loads(p.read_text())
            if isinstance(j, list):
                entries = len(j)
            elif isinstance(j, dict):
                entries = len(j.get("broken", []))
            else:
                entries = 0
            out.append({"file": str(p.name), "summary": {"entries": entries}})
        except Exception:
            out.append({"file": str(p.name), "summary": "invalid-json"})
    return out


def coverage_gaps(root: Path) -> Dict[str, Any]:
    # Simple heuristic: count policies and tests
    policy_count = sum(1 for _ in (root / "policies").rglob("*.yaml")) if (root / "policies").exists() else 0
    # tests under tests/kyverno and tests/gatekeeper
    test_count = 0
    if (root / "tests").exists():
        test_count = sum(1 for _ in (root / "tests").rglob("*test*.*"))
    missing = None
    if policy_count and test_count == 0:
        missing = "No tests found against policies"
    return {"policy_count": policy_count, "test_count": test_count, "missing_hint": missing}


def dependency_drift(root: Path) -> Dict[str, Any]:
    # Placeholder: look for requirements*.lock files
    locks = [str(p.name) for p in root.glob("requirements*.lock")]
    return {"lock_files": locks or [], "note": "Run pip-audit / pip-compile for details (placeholder)"}


def render_markdown(report: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append("# Readiness Report")
    lines.append("")
    lines.append(f"Generated: {datetime.now(UTC).isoformat()}")
    lines.append("")

    lines.append("## Summary")
    lines.append("")
    lines.append(report.get("summary", "N/A"))
    lines.append("")

    lines.append("## Changelog Diff")
    lines.append("")
    cd = report.get("changelog_diff") or ["N/A"]
    lines.extend(cd if isinstance(cd, list) else [str(cd)])
    lines.append("")

    lines.append("## Version Drift")
    lines.append("")
    vd = report.get("version_drift") or {}
    lines.append(json.dumps(vd, indent=2))
    lines.append("")

    lines.append("## Dependency Drift")
    lines.append("")
    dd = report.get("dependency_drift") or {}
    lines.append(json.dumps(dd, indent=2))
    lines.append("")

    lines.append("## TODO Findings")
    lines.append("")
    todos = report.get("todos") or []
    if not todos:
        lines.append("None")
    else:
        for t in todos[:200]:
            lines.append(f"- {t['file']}:{t['line']} {t['tag']} - {t['snippet']}")
    lines.append("")

    lines.append("## Link Issues")
    lines.append("")
    links = report.get("link_issues") or []
    if not links:
        lines.append("None")
    else:
        for link in links:
            lines.append("- {}: {}".format(link.get("file"), link.get("summary")))
    lines.append("")

    lines.append("## Coverage Gaps")
    lines.append("")
    lines.append(json.dumps(report.get("coverage_gaps") or {}, indent=2))
    lines.append("")

    lines.append("## Recommended Actions")
    lines.append("")
    ra = report.get("recommended_actions") or ["N/A"]
    lines.extend(ra if isinstance(ra, list) else [str(ra)])

    return "\n".join(lines)


def build_report(root: Path) -> Dict[str, Any]:
    out: Dict[str, Any] = {}
    git_info = find_latest_tag_vs_head(root)
    out["summary"] = "Readiness summary for RuleHub"
    out["git"] = git_info
    out["changelog_diff"] = changelog_diff(root, git_info.get("latest_tag", ""))
    out["version_drift"] = {
        "package.json": read_file_if_exists(root / "package.json") is not None,
        "release-please": read_file_if_exists(root / "release-please-config.json") is not None,
    }
    out["dependency_drift"] = dependency_drift(root)
    out["todos"] = scan_for_todos(root)
    out["link_issues"] = collect_link_issues(root)
    out["coverage_gaps"] = coverage_gaps(root)
    out["recommended_actions"] = [
        "Run pip-audit and npm audit for dependency issues",
        "Ensure policies under policies/ have paired tests under tests/",
        "Address TODO/FIXME items found in source",
    ]
    return out


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Produce readiness report for RuleHub")
    p.add_argument("--root", default=".", help="Repository root")
    p.add_argument("--out-dir", default="dist/release", help="Output directory")
    p.add_argument("--json", action="store_true", help="Also write JSON")
    args = p.parse_args(argv)

    root = Path(args.root).resolve()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    report = build_report(root)

    md = render_markdown(report)
    md_path = out_dir / "readiness.md"
    md_path.write_text(md)

    json_path = out_dir / "readiness.json"
    json_path.write_text(json.dumps(report, indent=2))

    print(f"Wrote: {md_path}\nWrote: {json_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
