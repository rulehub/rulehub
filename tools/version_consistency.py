"""version_consistency.py

Compare version sources and recommend next semver.

This tool is intentionally small and focused so unit tests can exercise the core logic
without scanning the entire repo. It supports a CLI wrapper for simple local usage.

Logic:
- If any commit message contains 'BREAKING CHANGE' or a conventional commit ending with '!'
  recommend a major bump.
- Else if any commit message contains 'feat' recommend a minor bump.
- Else recommend a patch bump.

Outputs a markdown table and a short justification. A --json flag emits a JSON payload.
"""

from __future__ import annotations

import argparse
import json
import os
import re
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple


try:
    import yaml  # type: ignore
except Exception:
    yaml = None  # pragma: no cover - YAML optional in some test environments


SEMVER_RE = re.compile(r"^(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)$")


@dataclass
class SourceVersion:
    source: str
    path: str
    version: Optional[str]


def read_json_file(path: str) -> Optional[Dict]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def read_yaml_file(path: str) -> Optional[Dict]:
    if yaml is None:
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except Exception:
        return None


def extract_versions(paths: List[Tuple[str, str]]) -> List[SourceVersion]:
    """Given list of (source_name, file_path) return discovered versions.

    Supported files: package.json (version), release-please-config.json (release-type not used),
    Chart.yaml (version/appVersion), generic package.json for plugins, requirements*.lock (search)
    """
    out: List[SourceVersion] = []
    for name, path in paths:
        ver = None
        if not os.path.exists(path):
            out.append(SourceVersion(name, path, None))
            continue

        lower = os.path.basename(path).lower()
        if lower.endswith("package.json"):
            data = read_json_file(path)
            if isinstance(data, dict):
                ver = data.get("version")
        elif os.path.basename(path).lower() == "release-please-config.json":
            data = read_json_file(path)
            # release-please config might contain a `packageName` / `bump-minor-pre-major` etc.
            # Not all configs include a version, so leave None when absent.
            if isinstance(data, dict):
                ver = data.get("version")
        elif lower.endswith("chart.yaml") or lower == "chart.yaml":
            data = read_yaml_file(path)
            if isinstance(data, dict):
                ver = data.get("version") or data.get("appVersion")
        elif lower.endswith(".lock"):
            # try reading header for a top-line version string like: # pip-compile: 2023.01.01 or similar
            try:
                with open(path, "r", encoding="utf-8") as f:
                    for _ in range(10):
                        line = f.readline()
                        if not line:
                            break
                        m = SEMVER_RE.search(line)
                        if m:
                            ver = m.group(0)
                            break
            except Exception:
                ver = None
        else:
            # fallback: try JSON then YAML
            data = read_json_file(path)
            if isinstance(data, dict):
                ver = data.get("version")
            else:
                data = read_yaml_file(path)
                if isinstance(data, dict):
                    ver = data.get("version")

        out.append(SourceVersion(name, path, str(ver) if ver is not None else None))

    return out


def recommend_bump_level(commit_messages: List[str]) -> str:
    """Return one of 'major','minor','patch' based on commit messages."""
    has_feat = False
    for msg in commit_messages:
        if "BREAKING CHANGE" in msg or re.search(r"\w+!", msg):
            return "major"
        if re.search(r"(^|\b)feat(\(|:|\b)", msg, re.IGNORECASE):
            has_feat = True
    if has_feat:
        return "minor"
    return "patch"


def bump_version(current: str, level: str) -> str:
    m = SEMVER_RE.match(current)
    if not m:
        # If current isn't semver, return current as-is for safety
        return current
    major = int(m.group("major"))
    minor = int(m.group("minor"))
    patch = int(m.group("patch"))
    if level == "major":
        major += 1
        minor = 0
        patch = 0
    elif level == "minor":
        minor += 1
        patch = 0
    else:
        patch += 1
    return f"{major}.{minor}.{patch}"


def aggregate_versions(sources: List[SourceVersion]) -> Dict[str, Optional[str]]:
    return {s.source: s.version for s in sources}


def render_markdown(sources: List[SourceVersion], recommended: str, rationale: str) -> str:
    lines = []
    lines.append("# Version consistency report")
    lines.append("")
    lines.append("| Source | Path | Version |")
    lines.append("|---|---|---|")
    for s in sources:
        lines.append(f"| {s.source} | {s.path} | {s.version or 'N/A'} |")
    lines.append("")
    lines.append(f"**Recommended next version:** {recommended}")
    lines.append("")
    lines.append("**Rationale:**")
    lines.append("")
    lines.append(rationale)
    return "\n".join(lines)


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Version consistency helper")
    parser.add_argument("--sources", nargs="*", help="Pairs of source:name=path", default=[])
    parser.add_argument("--commits-file", help="Path to a file with commit messages, one per line")
    parser.add_argument("--force-version", help="Force the recommended version to this value")
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    parser.add_argument("--out", help="Output markdown path", default=None)
    args = parser.parse_args(argv)

    # parse sources
    pairs: List[Tuple[str, str]] = []
    if args.sources:
        for item in args.sources:
            if "=" in item:
                name, path = item.split("=", 1)
                pairs.append((name, path))
    else:
        # sensible defaults at repo root
        repo_root = os.getcwd()
        pairs = [
            ("package.json", os.path.join(repo_root, "package.json")),
            ("release-please-config.json", os.path.join(repo_root, "release-please-config.json")),
            ("Chart.yaml", os.path.join(repo_root, "Chart.yaml")),
            ("requirements.lock (root)", os.path.join(repo_root, "requirements.lock")),
        ]

    sources = extract_versions(pairs)

    commit_messages: List[str] = []
    if args.commits_file and os.path.exists(args.commits_file):
        with open(args.commits_file, "r", encoding="utf-8") as f:
            commit_messages = [line.strip() for line in f if line.strip()]

    # pick a current version to bump from: prefer package.json -> chart -> lock
    current = None
    for candidate in [s for s in sources if s.version]:
        if candidate.source.lower().startswith("package.json"):
            current = candidate.version
            break
    if not current:
        for candidate in sources:
            if candidate.version:
                current = candidate.version
                break
    if not current:
        current = "0.0.0"

    if args.force_version:
        recommended = args.force_version
        rationale = f"User override via --force-version => {recommended}."
    else:
        level = recommend_bump_level(commit_messages)
        recommended = bump_version(current, level)
        rationale = f"Bump level determined as '{level}' from {len(commit_messages)} commit messages."

    md = render_markdown(sources, recommended, rationale)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(md)
    if args.json:
        payload = {"sources": aggregate_versions(sources), "recommended": recommended, "rationale": rationale}
        print(json.dumps(payload, indent=2))
    else:
        print(md)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
