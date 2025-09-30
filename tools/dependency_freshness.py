#!/usr/bin/env python3
"""Generate dependency freshness report for JS (package.json), Python (requirements*.txt) and optional images.

Outputs:
 - dist/release/deps.md (Markdown table)
 - dist/release/deps.json (JSON summary + per-dep entries)

Flags:
 --offline : do not query remote registries; mark latest as 'N/A' and status 'unknown (offline)'.
 --json    : also print JSON to stdout
 --images-dir : optional directory to scan for container image references (simple regex)

This is intentionally lightweight and avoids extra dependencies so it works in minimal envs.
"""
from __future__ import annotations

import argparse
import json
import re
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def read_package_json(path: Path) -> Dict[str, str]:
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    deps = {}
    for key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        for k, v in data.get(key, {}).items():
            deps.setdefault(k, v)
    return deps


def read_requirements_files(root: Path) -> Dict[str, str]:
    # look for requirements*.txt at repo root
    out: Dict[str, str] = {}
    for p in sorted(root.glob("requirements*.txt")):
        for line in p.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            # very small parser: pkg==version or pkg>=x
            m = re.match(
                r"^([A-Za-z0-9_.-]+)\s*(?:==|>=|<=|~=|!=)?\s*([A-Za-z0-9.\-+]*)", line)
            if m:
                name, ver = m.group(1), m.group(2) or ""
                out.setdefault(name, ver)
    return out


def scan_images(dirpath: Path) -> Dict[str, str]:
    images: Dict[str, str] = {}
    if not dirpath.exists():
        return images
    img_re = re.compile(
        r"([A-Za-z0-9\-_.]+/[A-Za-z0-9\-_.]+):([A-Za-z0-9_\-.]+)")
    for p in dirpath.rglob("*.yml"):
        for line in p.read_text(encoding="utf-8", errors="ignore").splitlines():
            m = img_re.search(line)
            if m:
                images.setdefault(m.group(1), m.group(2))
    return images


def fetch_pypi_latest(name: str, timeout: float = 5.0) -> Optional[str]:
    url = f"https://pypi.org/pypi/{name}/json"
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            data = json.load(r)
            return data.get("info", {}).get("version")
    except Exception:
        return None


def fetch_npm_latest(name: str, timeout: float = 5.0) -> Optional[str]:
    # npm registry may have scoped names; we quote
    url = f"https://registry.npmjs.org/{name}"
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            data = json.load(r)
            # 'dist-tags'.latest normally exists
            return data.get("dist-tags", {}).get("latest")
    except Exception:
        return None


def parse_semver(v: str) -> Tuple[int, int, int]:
    # crude semver parse: take numeric components, pad with zeros
    parts = re.findall(r"\d+", v)
    parts = (parts + ["0", "0", "0"])[:3]
    return (int(parts[0]), int(parts[1]), int(parts[2]))


def compare_versions(a: str, b: str) -> int:
    # return -1 if a<b, 0 if equal, 1 if a>b for simple semver-like numbers
    try:
        pa = parse_semver(a)
        pb = parse_semver(b)
        if pa < pb:
            return -1
        if pa > pb:
            return 1
        return 0
    except Exception:
        return 0


def classify_entry(current: str, latest: Optional[str], offline: bool) -> Tuple[str, Optional[str]]:
    if offline:
        return "unknown (offline)", None
    if not latest:
        return "unknown", None
    if not current:
        return "unknown", None
    cmp = compare_versions(current, latest)
    if cmp >= 0:
        return "up-to-date", None
    # determine security-critical if major bump
    try:
        cur_major = parse_semver(current)[0]
        lat_major = parse_semver(latest)[0]
        if lat_major > cur_major:
            return "update-available", "security-critical"
    except Exception:
        pass
    return "update-available", None


def generate_report(entries: List[Dict], out_dir: Path) -> None:
    md_lines: List[str] = []
    md_lines.append("# Dependency Freshness Report\n")
    md_lines.append("|name|current|latest|status|notes|")
    md_lines.append("|-|-|-|-|-|")
    for e in entries:
        notes = e.get("notes") or ""
        md_lines.append(
            f"|{e['name']}|{e.get('current', '')}|{e.get('latest', '')}|{e.get('status', '')}|{notes}|")

    out_dir.mkdir(parents=True, exist_ok=True)
    md_path = out_dir / "deps.md"
    json_path = out_dir / "deps.json"
    md_path.write_text("\n".join(md_lines) + "\n", encoding="utf-8")
    json_path.write_text(
        json.dumps({"summary": summary_from_entries(
            entries), "entries": entries}, indent=2),
        encoding="utf-8",
    )


def summary_from_entries(entries: List[Dict]) -> Dict:
    total = len(entries)
    up = sum(1 for e in entries if e.get("status") == "up-to-date")
    avail = sum(1 for e in entries if e.get("status") == "update-available")
    unknown = sum(1 for e in entries if e.get(
        "status", "").startswith("unknown"))
    sec = sum(1 for e in entries if e.get("notes")
              and "security-critical" in (e.get("notes") or ""))
    return {"total": total, "up_to_date": up, "update_available": avail, "unknown": unknown, "security_critical": sec}


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(prog="dependency_freshness.py")
    p.add_argument("--offline", action="store_true",
                   help="Do not query remote registries")
    p.add_argument("--json", action="store_true",
                   help="Also print JSON to stdout")
    p.add_argument("--images-dir", type=str, default=None,
                   help="Optional dir to scan YAML for image references")
    args = p.parse_args(argv)

    repo_root = Path.cwd()
    pkg = read_package_json(repo_root / "package.json")
    pyreqs = read_requirements_files(repo_root)
    images = {}
    if args.images_dir:
        images = scan_images(Path(args.images_dir))

    entries: List[Dict] = []

    # JS deps
    for name, ver in sorted(pkg.items()):
        current = ver.lstrip("^~>=<")
        latest = None if args.offline else fetch_npm_latest(name)
        status, note = classify_entry(current, latest, args.offline)
        notes = note or ""
        entries.append(
            {
                "ecosystem": "npm",
                "name": name,
                "current": current,
                "latest": latest or ("N/A" if args.offline else "unknown"),
                "status": status,
                "notes": notes,
            }
        )

    # Python
    for name, ver in sorted(pyreqs.items()):
        current = ver
        latest = None if args.offline else fetch_pypi_latest(name)
        status, note = classify_entry(current, latest, args.offline)
        notes = note or ""
        entries.append(
            {
                "ecosystem": "pypi",
                "name": name,
                "current": current,
                "latest": latest or ("N/A" if args.offline else "unknown"),
                "status": status,
                "notes": notes,
            }
        )

    # images
    for img, tag in sorted(images.items()):
        entries.append(
            {
                "ecosystem": "image",
                "name": img,
                "current": tag,
                "latest": "N/A",
                "status": "not-checked",
                "notes": "image scans are optional",
            }
        )

    out_dir = repo_root / "dist" / "release"
    generate_report(entries, out_dir)

    if args.json:
        print(json.dumps({"summary": summary_from_entries(
            entries), "entries": entries}, indent=2))

    print(f"Wrote: {out_dir / 'deps.md'} and {out_dir / 'deps.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
