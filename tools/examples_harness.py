#!/usr/bin/env python3
"""Selective execution harness for documentation examples.

Reads an index file (default: docs/examples.index) that specifies explicit
example code ranges inside markdown files and executes them under controlled
conditions similar to `test_examples.py`, but restricted to only the listed
ranges.

Index Format (pipe-delimited):
  <file.md>#L<start>-L<end> | id=<slug> | expect=<regex?> | flags=<csv?>

Rules:
  * Lines beginning with '#' or blank are ignored.
  * File path is relative to docs/ unless absolute.
  * Start/End refer to literal line numbers inside the markdown file (1-based).
    The specified range should contain ONLY the code lines (no opening/closing
    fences). The harness does not attempt to strip backticks.
  * The extracted code snippet is executed with `bash -euo pipefail` if the
    first non-comment line appears shell-like. (For now we assume bash/sh
    content; future extension could add language detection.)
  * expect=<regex> if provided must match stdout (full multiline) of execution.
  * flags can contain:
      - skip: do not execute (reported as skipped)
      - allow-network: disable naive network command denylist

Safety:
  * Basic denylist for network-touching commands unless allow-network flag set.
  * Execution occurs in a temporary directory with env RULEHUB_EXAMPLES_SANDBOX=1.

Output: JSON summary to stdout:
  {"total":N,"passed":P,"failed":F,"skipped":S,"examples":[...]}
Exit code non-zero iff failed > 0.

Schema version: 1 (subject to extension).
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
from typing import List, Optional


INDEX_LINE_RE = re.compile(
    r"^([^#|]+)#L(\d+)-L(\d+)\s*\|\s*id=([a-zA-Z0-9_.-]+)"
    r"(?:\s*\|\s*expect=([^|]+))?(?:\s*\|\s*flags=([^|]+))?\s*$"
)
NETWORK_DENY = {"curl", "wget", "apt", "apk", "yum", "dnf"}


@dataclass
class HarnessResult:
    id: str
    file: str
    start_line: int
    end_line: int
    status: str  # passed|failed|skipped
    expect: Optional[str]
    flags: List[str]
    error: Optional[str] = None
    stdout_snippet: Optional[str] = None


def parse_index(index_path: Path, docs_root: Path) -> List[tuple[Path, int, int, str, Optional[str], List[str]]]:
    entries: List[tuple[Path, int, int, str, Optional[str], List[str]]] = []
    for raw in index_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = INDEX_LINE_RE.match(line)
        if not m:
            raise ValueError(f"Invalid index line: {line}")
        rel_file, s_start, s_end, ex_id, expect_raw, flags_raw = m.groups()
        start, end = int(s_start), int(s_end)
        file_path = docs_root / rel_file
        if not file_path.is_file():
            raise FileNotFoundError(f"Referenced doc not found: {file_path}")
        expect = expect_raw.strip() if expect_raw else None
        flags = [f.strip() for f in flags_raw.split(',')] if flags_raw else []
        entries.append((file_path, start, end, ex_id, expect, flags))
    return entries


def extract_code(file_path: Path, start: int, end: int) -> List[str]:
    lines = file_path.read_text(encoding="utf-8").splitlines()
    if start < 1 or end > len(lines) or start > end:
        raise ValueError(f"Invalid line range {start}-{end} for {file_path}")
    # Lines are 1-based inclusive
    return lines[start - 1: end]


def violates_network_policy(block: List[str]) -> bool:
    for ln in block:
        tokens = re.split(r"\s+|;|&&|\|\|", ln.strip())
        for t in tokens:
            if t in NETWORK_DENY:
                return True
    return False


def run_block(block: List[str]) -> tuple[str, str | None, str]:
    script = ["set -euo pipefail"] + block
    content = "\n".join(script) + "\n"
    with tempfile.TemporaryDirectory(prefix="rulehub_ex_harness_") as tmp:
        env = os.environ.copy()
        env["RULEHUB_EXAMPLES_SANDBOX"] = "1"
        try:
            proc = subprocess.run(
                ["bash", "-c", content],
                cwd=tmp,
                env=env,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            return "passed", None, proc.stdout
        except subprocess.CalledProcessError as e:
            return "failed", e.stdout.strip(), e.stdout


def main() -> int:
    ap = argparse.ArgumentParser(description="Selective example harness")
    ap.add_argument("--index", default="docs/examples.index",
                    help="Index file path")
    ap.add_argument("--docs", default="docs", help="Docs root directory")
    ap.add_argument("--json", default="-",
                    help="Output JSON path or - for stdout")
    args = ap.parse_args()

    docs_root = Path(args.docs)
    index_path = Path(args.index)

    entries = parse_index(index_path, docs_root)
    results: List[HarnessResult] = []

    for file_path, start, end, ex_id, expect, flags in entries:
        status = "passed"
        error = None
        stdout_full = None
        try:
            code_lines = extract_code(file_path, start, end)
        except Exception as e:  # capture extraction errors
            results.append(HarnessResult(ex_id, str(file_path),
                           start, end, "failed", expect, flags, error=str(e)))
            continue
        if "skip" in flags:
            status = "skipped"
        elif "allow-network" not in flags and violates_network_policy(code_lines):
            status = "failed"
            error = "network command detected"
        else:
            status, run_err, stdout_full = run_block(code_lines)
            if status == "failed":
                error = (run_err or "execution failed")[:400]
        # Expect regex check
        if status == "passed" and expect:
            if not re.search(expect, stdout_full or "", re.MULTILINE):
                status = "failed"
                error = f"expect regex '{expect}' not found in output"
        results.append(
            HarnessResult(
                id=ex_id,
                file=str(file_path.relative_to(docs_root)),
                start_line=start,
                end_line=end,
                status=status,
                expect=expect,
                flags=flags,
                error=error,
                stdout_snippet=(stdout_full or "")[
                    :200] if stdout_full else None,
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

    out = json.dumps(summary, indent=2, ensure_ascii=False) + "\n"
    if args.json == "-":
        sys.stdout.write(out)
    else:
        Path(args.json).write_text(out, encoding="utf-8")
        print(f"Wrote {args.json}")
    return 0 if summary["failed"] == 0 else 2


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
