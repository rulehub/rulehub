#!/usr/bin/env python3
import json
import sys
from pathlib import Path

import yaml


try:
    import jsonschema
except Exception:
    print("Missing dependency jsonschema. Install with: pip install jsonschema", file=sys.stderr)
    sys.exit(2)

SCHEMA_PATH = Path(__file__).parent / "schemas" / "compliance-map.schema.json"
MAPS_DIR = Path("compliance/maps")
POLICY_ROOT = Path("policies")


def collect_policy_ids() -> set[str]:
    """Scan policies/**/metadata.yaml and return a set of known policy IDs.

    If an entry lacks 'id', attempt to derive it from folder structure
    policies/<namespace>/<short_id>/metadata.yaml -> <namespace>.<short_id>.
    """
    ids: set[str] = set()
    for meta in POLICY_ROOT.glob("**/metadata.yaml"):
        try:
            with open(meta, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f) or {}
        except Exception:
            continue
        pid = data.get("id")
        if not pid:
            parts = meta.parent.parts
            try:
                pol_idx = parts.index("policies")
                ns = parts[pol_idx + 1]
                short = parts[pol_idx + 2]
                pid = f"{ns}.{short}"
            except Exception:
                pid = None
        if isinstance(pid, str):
            ids.add(pid)
    return ids


def main() -> int:
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        schema = json.load(f)
    validator = jsonschema.Draft7Validator(schema)

    errors = 0
    known_ids = collect_policy_ids()
    for mp in sorted(MAPS_DIR.glob("*.yml")):
        with open(mp, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        for err in sorted(validator.iter_errors(data), key=lambda e: e.path):
            print(f"Schema error in {mp}: {err.message}")
            errors += 1
        # extra light checks
        sections = (data or {}).get("sections") or {}
        for sec, val in sections.items():
            pols = (val or {}).get("policies") or []
            if not isinstance(pols, list) or not pols:
                print(f"Warning: section '{sec}' in {mp} has no policies listed")
        # basic duplicate policy id detection per map
        seen = set()
        dups = set()
        for val in sections.values():
            for pid in (val or {}).get("policies") or []:
                if pid in seen:
                    dups.add(pid)
                else:
                    seen.add(pid)
        if dups:
            print(f"Warning: duplicate policies in {mp}: {', '.join(sorted(dups))}")

        # Referential integrity: policies referenced in maps must exist in metadata
        unknown = set()
        for val in sections.values():
            for pid in (val or {}).get("policies") or []:
                if pid not in known_ids:
                    unknown.add(pid)
        if unknown:
            print(
                f"Unknown policy id(s) referenced in {mp}: {', '.join(sorted(unknown))}"
            )
            errors += len(unknown)

    if errors:
        print(f"Validation failed with {errors} error(s).", file=sys.stderr)
        return 1
    print("All compliance maps are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
