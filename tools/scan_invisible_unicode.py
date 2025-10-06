#!/usr/bin/env python3
"""
Scan repository text files for invisible/zero-width Unicode characters and report positions.

Excludes common generated/ignored paths: dist/, site/, node_modules/, .venv/, build/.
Only scans files tracked by git to avoid scanning virtualenvs or caches.

Outputs: dist/invisible-unicode-report.txt (UTF-8)
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


EXCLUDE_PREFIXES = (
    "dist/",
    "site/",
    "node_modules/",
    ".venv/",
    "build/",
)

# Zero-width and control-like codepoints to flag; extend as needed.
SUSPECT_CODEPOINTS = {
    0x200B: "ZERO WIDTH SPACE",
    0x200C: "ZERO WIDTH NON-JOINER",
    0x200D: "ZERO WIDTH JOINER",
    0x2060: "WORD JOINER",
    0x00A0: "NO-BREAK SPACE",
    0xFEFF: "ZERO WIDTH NO-BREAK SPACE (BOM)",
}


def is_text_file(path: Path) -> bool:
    # Heuristic: scan common text extensions; skip obvious binaries.
    text_exts = {
        ".md",
        ".yml",
        ".yaml",
        ".json",
        ".rego",
        ".py",
        ".toml",
        ".ini",
        ".mk",
        ".sh",
        ".txt",
    }
    return path.suffix.lower() in text_exts


def main() -> int:
    repo = Path.cwd()
    # Ensure dist exists
    (repo / "dist").mkdir(parents=True, exist_ok=True)
    report_path = repo / "dist" / "invisible-unicode-report.txt"

    try:
        out = subprocess.check_output(
            ["bash", "-lc", "git ls-files"], stderr=subprocess.STDOUT)
        files = [Path(line.strip())
                 for line in out.decode().splitlines() if line.strip()]
    except Exception as e:
        print(f"Failed to list git-tracked files: {e}", file=sys.stderr)
        return 2

    findings: list[str] = []
    for p in files:
        sp = str(p).replace("\\", "/")
        if any(sp.startswith(prefix) for prefix in EXCLUDE_PREFIXES):
            continue
        if not is_text_file(p):
            continue
        try:
            data = p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        for i, line in enumerate(data.splitlines(keepends=False), start=1):
            for j, ch in enumerate(line, start=1):
                cp = ord(ch)
                if cp in SUSPECT_CODEPOINTS:
                    findings.append(
                        f"{sp}:{i}:{j}: U+{cp:04X} {SUSPECT_CODEPOINTS[cp]}"
                    )

    if not findings:
        report = "No invisible/zero-width Unicode characters found in scanned files.\n"
    else:
        report = "\n".join(findings) + "\n"

    report_path.write_text(report, encoding="utf-8")
    print(f"Wrote {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
