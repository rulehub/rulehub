#!/usr/bin/env python3
"""Fail if deprecated Gatekeeper-style 'violation[' usages appear in Rego sources.

Context: Repository standardizes on OPA `deny[msg]` rules. Prior to first
release we forbid committing any `violation[` rule patterns outside docs
illustrative examples.

Behavior:
  * Scan *.rego and *.rego.tmpl under templates/ and addons/.
  * Ignore anything under docs/ (examples / narrative allowed there).
  * Report each offending line and exit 1 if any found.
"""
from __future__ import annotations

import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGET_DIRS = [ROOT / "templates", ROOT / "addons"]

hits: list[tuple[pathlib.Path, int, str]] = []

for base in TARGET_DIRS:
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in {".rego", ".tmpl"}:
            continue
        if ".rego" not in path.name and path.suffix != ".rego":
            # Only enforce real rego (plain .tmpl may be other content)
            continue
        rel = path.relative_to(ROOT)
        if str(rel).startswith("docs/"):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:  # pragma: no cover - unreadable file
            continue
        for ln, line in enumerate(text.splitlines(), start=1):
            if "violation[" in line:
                hits.append((rel, ln, line.strip()))

if hits:
    print(
        "Forbidden 'violation[' rule syntax detected; use deny[msg] instead:", file=sys.stderr)
    for rel, ln, snippet in hits:
        print(f"  {rel}:{ln}: {snippet}", file=sys.stderr)
    print(
        "\nFix: rename rule heads to deny[\"<id>\"] and adjust tests.", file=sys.stderr)
    sys.exit(1)

print("deny-usage-scan: OK (no 'violation[' tokens found)")
