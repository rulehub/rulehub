#!/usr/bin/env python3
"""Execute whitelisted shell example blocks from documentation.

Scan all markdown files under docs/ for fenced code blocks with language
`bash` or `sh` that contain the allowlist marker `# example-test` on any
line of the block. Each such block is executed in an isolated temporary
directory using `bash` with `set -euo pipefail` enforced. A JSON summary
is printed to stdout:

  {"total": N, "passed": P, "failed": F, "skipped": S, "examples": [...]}

Exit code is non‑zero iff failed > 0.

Heuristics / Safety:
  * Basic static denylist of obvious network commands (curl,wget,apt,apk)
    – if encountered the block is marked failed without execution.
  * Environment variable RULEHUB_EXAMPLES_SANDBOX=1 is exported so the
    executed snippet can choose safer branches.
  * A block line containing `# skip` causes the block to be counted as
    skipped (useful for future placeholders).

Limitations: Full network isolation would normally require container /
namespaces; here we rely on static scanning to prevent unintended use.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List


FENCE_RE = re.compile(r"^```(bash|sh)\s*$")
END_FENCE_RE = re.compile(r"^```\s*$")
ALLOW_MARKER = "# example-test"
SKIP_MARKER = "# skip"
NETWORK_DENY = {"curl", "wget", "apt", "apk", "yum", "dnf"}


@dataclass
class ExampleResult:
    file: str
    start_line: int
    end_line: int
    language: str
    status: str  # passed|failed|skipped
    command_count: int
    error: str | None = None


def extract_examples(root: Path) -> List[tuple[Path, int, int, str, List[str]]]:
    examples: List[tuple[Path, int, int, str, List[str]]] = []
    for md in sorted(root.glob("*.md")):
        lines = md.read_text(encoding="utf-8").splitlines()
        i = 0
        while i < len(lines):
            m = FENCE_RE.match(lines[i])
            if not m:
                i += 1
                continue
            lang = m.group(1)
            start = i + 1
            block: List[str] = []
            i += 1
            while i < len(lines) and not END_FENCE_RE.match(lines[i]):
                block.append(lines[i])
                i += 1
            end_line = i  # fence line (```)
            # Advance past closing fence if present
            if i < len(lines) and END_FENCE_RE.match(lines[i]):
                i += 1
            # Filter: must contain allow marker
            if not any(ALLOW_MARKER in ln for ln in block):
                continue
            examples.append((md, start + 1, end_line, lang, block))
        # next file
    return examples


def violates_network_policy(block: List[str]) -> bool:
    for ln in block:
        # naive token split
        tokens = re.split(r"\s+|;|&&|\|\|", ln.strip())
        for t in tokens:
            if t in NETWORK_DENY:
                return True
    return False


def run_block(block: List[str]) -> tuple[str, str | None]:
    script = [
        "set -euo pipefail",
    ]
    script.extend(block)
    content = "\n".join(script) + "\n"
    with tempfile.TemporaryDirectory(prefix="rulehub_example_") as tmp:
        env = os.environ.copy()
        env["RULEHUB_EXAMPLES_SANDBOX"] = "1"
        # Execute using bash -c
        try:
            subprocess.run(
                ["bash", "-c", content],
                cwd=tmp,
                env=env,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            return "passed", None
        except subprocess.CalledProcessError as e:
            return "failed", truncate(e.stdout)


def truncate(text: str, limit: int = 400) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[: limit - 20] + "...<truncated>"


def main() -> int:
    parser = argparse.ArgumentParser(description="Execute whitelisted shell example blocks from docs/")
    parser.add_argument("--docs", default="docs", help="Docs directory (default: docs)")
    parser.add_argument("--json", default="-", help="Output JSON path or - for stdout")
    args = parser.parse_args()

    docs_root = Path(args.docs)
    examples = extract_examples(docs_root)
    results: List[ExampleResult] = []
    for md, start, end, lang, block in examples:
        status = "passed"
        error: str | None = None
        if any(SKIP_MARKER in ln for ln in block):
            status = "skipped"
        elif violates_network_policy(block):
            status = "failed"
            error = "network command detected"
        else:
            status, error = run_block(block)
        results.append(
            ExampleResult(
                file=str(md),
                start_line=start,
                end_line=end,
                language=lang,
                status=status,
                command_count=sum(1 for ln in block if ln.strip() and not ln.strip().startswith("#")),
                error=error,
            )
        )

    summary = {
        "total": len(results),
        "passed": sum(1 for r in results if r.status == "passed"),
        "failed": sum(1 for r in results if r.status == "failed"),
        "skipped": sum(1 for r in results if r.status == "skipped"),
        "examples": [asdict(r) for r in results],
        "schema_version": 1,
    }

    out_json = json.dumps(summary, indent=2, ensure_ascii=False) + "\n"
    if args.json == "-":
        sys.stdout.write(out_json)
    else:
        Path(args.json).write_text(out_json, encoding="utf-8")
        print(f"Wrote {args.json}")

    return 0 if summary["failed"] == 0 else 2


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
