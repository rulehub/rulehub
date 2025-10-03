#!/usr/bin/env python3
"""Export (id, name, links[]) from all policy metadata.yaml files to JSON.

Usage:
  python tools/export_links.py output.json

The JSON schema matches the audit prompt expectation:
{
  "policies": [
    {"id": "...", "name": "...", "links": ["url1", "url2"]},
    ...
  ]
}
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict, List

from tools.lib.metadata_loader import load_all_metadata


def collect() -> List[Dict[str, Any]]:
    items: List[Dict[str, Any]] = []
    for pid, meta, loaded in load_all_metadata("policies"):
        pid_obj = loaded.get("id")
        pid_val: str | None = pid_obj if isinstance(pid_obj, str) else None
        name_obj = loaded.get("name")
        name: str = name_obj if isinstance(name_obj, str) else (pid_val or meta.parent.name)
        links_obj = loaded.get("links")
        if isinstance(links_obj, list):
            links: List[str] = [u for u in links_obj if isinstance(u, str)]
        else:
            links = []
        if pid_val:
            items.append({"id": pid_val, "name": name, "links": links})
    items.sort(key=lambda x: x["id"])
    return items


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: export_links.py output.json", file=sys.stderr)
        return 2
    out = Path(sys.argv[1])
    policies = collect()
    out.write_text(json.dumps({"policies": policies}, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
