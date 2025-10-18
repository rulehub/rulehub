#!/usr/bin/env bash
set -euo pipefail

# Activate venv and ensure a YAML library is present, then run the checker in --check mode.

if [ -d .venv ]; then
  # shellcheck source=/dev/null
  . .venv/bin/activate
fi

python - <<'PY' || pip install --no-input pyyaml
import importlib.util, sys
def has_mod(name: str) -> bool:
    try:
        return importlib.util.find_spec(name) is not None
    except ModuleNotFoundError:
        return False
ok = has_mod('ruamel.yaml') or has_mod('yaml')
sys.exit(0 if ok else 1)
PY

python tools/fix_compliance_map_dupes.py --check
