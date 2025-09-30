#!/usr/bin/env python3
"""Generate a markdown summary for a PR: changed policy IDs + test coverage deltas.

Outputs markdown to stdout. Intended for use in CI (pull_request event).

Metrics derived from dist/policy-test-coverage.json (produced earlier in the job).

Sections:
  - Policy Changes (new/modified policies)
  - Test Threshold Metrics (head vs base if available)
  - Coverage Delta Table

Gracefully handles missing base coverage JSON (e.g., first introduction).
"""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Set

import yaml  # type: ignore


POLICIES_DIR = Path("policies")
COVERAGE_JSON = Path("dist/policy-test-coverage.json")


def run(cmd: List[str]) -> str:
    return subprocess.check_output(cmd).decode("utf-8")


def git_changed_files(base: str, head: str) -> List[str]:
    out = run(["git", "diff", "--name-only", f"{base}..{head}"])
    return [line for line in out.splitlines() if line]


def load_policy_id(policy_dir: Path) -> str | None:
    meta = policy_dir / "metadata.yaml"
    if not meta.exists():
        return None
    try:
        data = yaml.safe_load(meta.read_text(encoding="utf-8")) or {}
    except Exception:
        return None
    if isinstance(data, dict) and data.get("id"):
        return str(data["id"]).strip()
    return None


def derive_changed_policy_ids(changed_files: List[str]) -> Set[str]:
    ids: Set[str] = set()
    for f in changed_files:
        if not f.startswith("policies/"):
            continue
        p = Path(f)
        # Ascend until we find metadata.yaml
        cur = p if p.is_dir() else p.parent
        while cur != cur.parent and cur.parts and cur.parts[0] == "policies":
            pid = load_policy_id(cur)
            if pid:
                ids.add(pid)
                break
            cur = cur.parent
    return ids


def git_show(path: str, ref: str) -> str | None:
    try:
        return run(["git", "show", f"{ref}:{path}"])
    except subprocess.CalledProcessError:
        return None


def load_json(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_base_coverage(base_ref: str) -> Dict[str, Any]:
    txt = git_show(str(COVERAGE_JSON), base_ref)
    if not txt:
        return {}
    try:
        return json.loads(txt)
    except Exception:
        return {}


def metric_extract(data: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "dual_direction.percent": data.get("dual_direction", {}).get("percent"),
        "multi_rule.count_inadequate": data.get("multi_rule", {}).get("count_inadequate"),
        # prior violation[] metric removed
    }


def format_delta(base, head) -> str:
    if base is None or base == "":
        return "—"
    if head is None or head == "":
        return "—"
    if isinstance(base, (int, float)) and isinstance(head, (int, float)):
        diff = head - base
        sign = "+" if diff > 0 else "" if diff < 0 else "="
        if isinstance(base, float) or isinstance(head, float):
            return f"{sign}{diff:.2f}"
        return f"{sign}{diff}"
    return "=" if base == head else "→"


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-ref", required=True)
    ap.add_argument("--head-ref", required=True)
    args = ap.parse_args(argv)

    changed_files = git_changed_files(args.base_ref, args.head_ref)
    changed_policy_ids = sorted(derive_changed_policy_ids(changed_files))

    head_cov = load_json(COVERAGE_JSON)
    base_cov = load_base_coverage(args.base_ref)
    head_metrics = metric_extract(head_cov)
    base_metrics = metric_extract(base_cov) if base_cov else {}

    print("### Policy Changes")
    if changed_policy_ids:
        for pid in changed_policy_ids:
            print(f"- `{pid}`")
    else:
        print("(None detected in policies/)")
    print()
    print("### Test Threshold Metrics")
    if not head_cov:
        print("Coverage JSON not generated; ensure `make policy-test-coverage` was run.")
    else:
        for k, v in head_metrics.items():
            base_val = base_metrics.get(k)
            delta = format_delta(base_val, v)
            label = k.replace("dual_direction.percent", "Dual Direction %").replace(
                "multi_rule.count_inadequate", "Multi-Rule Inadequate Count"
            )
            if base_val is None:
                print(f"- {label}: {v} (base: n/a)")
            else:
                print(f"- {label}: {v} (was {base_val}, Δ {delta})")
    print()
    print("### Coverage Delta Table")
    headers = ["Metric", "Base", "Head", "Δ"]
    print("| " + " | ".join(headers) + " |")
    print("| " + " | ".join(["---"] * len(headers)) + " |")
    for key, label in [
        ("dual_direction.percent", "Dual Direction %"),
        ("multi_rule.count_inadequate", "Multi-Rule Inadequate Count"),
    ]:
        base_val = base_metrics.get(key)
        head_val = head_metrics.get(key)
        delta = format_delta(base_val, head_val)
    base_display = base_val if base_val is not None else 'n/a'
    head_display = head_val if head_val is not None else 'n/a'
    print(f"| {label} | {base_display} | {head_display} | {delta} |")

    print("\n*Generated by pr-policy-summary workflow.*")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
