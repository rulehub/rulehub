#!/usr/bin/env python3
"""
Sort 'policies' lists alphabetically in compliance/maps/*.yml.
- If 'sections' exists: sort each section's policies.
- If top-level 'policies' exists: sort it.
Writes files in-place preserving key order.
"""

from __future__ import annotations

from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "compliance" / "maps"


def sort_policies_in_map(path: Path) -> bool:
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    changed = False
    if isinstance(data, dict):
        if isinstance(data.get("sections"), dict):
            for sec_key, sec in data["sections"].items():
                if isinstance(sec, dict) and isinstance(sec.get("policies"), list):
                    pols = sec["policies"]
                    sorted_pols = sorted(pols)
                    if pols != sorted_pols:
                        sec["policies"] = sorted_pols
                        changed = True
        if isinstance(data.get("policies"), list):
            pols = data["policies"]
            sorted_pols = sorted(pols)
            if pols != sorted_pols:
                data["policies"] = sorted_pols
                changed = True
    if changed:
        path.write_text(yaml.safe_dump(data, sort_keys=False,
                        allow_unicode=True), encoding="utf-8")
    return changed


def main() -> int:
    changed_any = False
    for yml in sorted(MAPS.glob("*.yml")):
        if yml.name.startswith("tmp/"):
            continue
        try:
            if sort_policies_in_map(yml):
                print(f"Sorted: {yml.relative_to(ROOT)}")
                changed_any = True
        except Exception as e:
            print(f"[WARN] Failed to process {yml}: {e}")
    print("Done.")
    return 0 if changed_any else 0


if __name__ == "__main__":
    raise SystemExit(main())
