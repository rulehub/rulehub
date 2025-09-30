#!/usr/bin/env python3
"""Batch test creator: orchestrate per-deny-count generators across policies.

Flags supported:
  --policies-root (default: policies)
  --list-file (newline or JSON array of policy paths, relative to policies-root)
  --policy (single policy path)
  --dry-run (do not write or call generators)
  --force (allow overwriting existing tests)
  --post-coverage (run coverage_enhancer after applying changes)

Behavior:
  - For each target policy, detect deny rule count and pick the matching
    generator: tools/gen_policy_tests_2.py / _3.py / _4.py.
  - In dry-run mode only print planned actions. In apply mode invoke the
    generator with --apply and pass --force when asked.
  - If deny count is unsupported, print a suggestion and skip.

This tool follows the repository conventions used by other tooling in `tools/`.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import List, Optional


GEN_MAP = {
    2: Path(__file__).with_name('gen_policy_tests_2.py'),
    3: Path(__file__).with_name('gen_policy_tests_3.py'),
    4: Path(__file__).with_name('gen_policy_tests_4.py'),
}


def read_list_file(p: Path) -> List[str]:
    text = p.read_text(encoding='utf-8')
    text = text.strip()
    if not text:
        return []
    # try JSON array first
    try:
        arr = json.loads(text)
        if isinstance(arr, list):
            return [str(x) for x in arr]
    except Exception:
        pass
    # fallback: newline separated
    return [line.strip() for line in text.splitlines() if line.strip()]


def deny_count(policy_path: Path) -> int:
    try:
        txt = policy_path.read_text(encoding='utf-8')
    except Exception:
        return 0
    return sum(1 for line in txt.splitlines() if line.strip().startswith('deny'))


def choose_generator(deny: int) -> Optional[Path]:
    return GEN_MAP.get(deny)


def run_generator_script(script: Path, policies_root: Path, policy_rel: Path, dry_run: bool, force: bool) -> int:
    cmd = [sys.executable, str(script), '--policies-root',
           str(policies_root), '--policy', str(policy_rel), '--apply']
    if force:
        cmd.append('--force')
    if dry_run:
        print(f"(dry-run) Would run: {' '.join(cmd)}")
        return 0
    print(f"Running generator: {' '.join(cmd)}")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(
            f"Generator {script} failed for {policy_rel}: {proc.returncode}\n{proc.stdout}\n{proc.stderr}")
    else:
        print(proc.stdout.strip())
    return proc.returncode


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--policies-root', default='policies')
    ap.add_argument(
        '--list-file', help='File listing policies (newline or JSON array)')
    ap.add_argument(
        '--policy', help='Single policy path to target (relative to policies-root or absolute)')
    ap.add_argument('--dry-run', action='store_true',
                    help='Only show actions; do not write')
    ap.add_argument(
        '--apply',
        action='store_true',
        help='Actually invoke generators and write changes (must be explicit)',
    )
    ap.add_argument('--force', action='store_true',
                    help='Allow overwriting existing tests')
    ap.add_argument('--post-coverage', action='store_true',
                    help='Run coverage_enhancer after (apply mode)')
    args = ap.parse_args(argv)

    policies_root = Path(args.policies_root)
    if not policies_root.exists():
        print(f"Policies root {policies_root} does not exist")
        return 2

    targets: List[Path] = []

    if args.list_file:
        lf = Path(args.list_file)
        if not lf.exists():
            print(f"List file {lf} not found")
            return 3
        for entry in read_list_file(lf):
            p = Path(entry)
            if not p.is_absolute():
                p = policies_root / p
            targets.append(p.resolve())

    if args.policy:
        p = Path(args.policy)
        if not p.is_absolute():
            p = policies_root / p
        targets.append(p.resolve())

    # If no explicit targets, scan all policy.rego files under policies_root
    if not targets:
        targets = sorted([p.resolve()
                         for p in policies_root.glob('**/policy.rego')])

    if not targets:
        print('No policies found to process')
        return 0

    exit_code = 0
    processed = 0
    for pol in targets:
        if not pol.exists():
            print(f"Skipping missing policy: {pol}")
            continue
        deny = deny_count(pol)
        gen = choose_generator(deny)
        rel = pol.relative_to(policies_root) if str(
            pol).startswith(str(policies_root)) else pol
        if not gen:
            print(
                f"No generator for policy {rel} (deny_count={deny}); please handle manually")
            continue
        # Require explicit --apply to actually run generators; default is dry-run.
        effective_dry = args.dry_run or not args.apply
        rc = run_generator_script(
            gen, policies_root, rel, dry_run=effective_dry, force=args.force)
        if rc != 0:
            exit_code = rc if exit_code == 0 else exit_code
        else:
            processed += 1

    print(f"Processed {processed} policies (applied={args.apply})")

    if args.post_coverage and args.apply:
        cov = Path(__file__).with_name('coverage_enhancer.py')
        if cov.exists():
            print('Running coverage_enhancer...')
            proc = subprocess.run([sys.executable, str(
                cov), '--policies-root', str(policies_root)])
            if proc.returncode != 0:
                print('coverage_enhancer failed')
                exit_code = proc.returncode
        else:
            print('coverage_enhancer.py not found; skipping post-coverage')

    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
