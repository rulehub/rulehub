#!/usr/bin/env bash
set -euo pipefail

format="both"
while [ $# -gt 0 ]; do
  case "$1" in
    --format) format="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

run_refs() {
  python tools/generate_refs_index.py --format "$format" || true
}

if [ -x .venv/bin/python ]; then
  . .venv/bin/activate
  if python -c "import yaml" >/dev/null 2>&1; then
    run_refs
    exit 0
  else
    deactivate || true
  fi
fi

if [ -x /opt/ci-venv/bin/python ] && /opt/ci-venv/bin/python -c "import yaml" >/dev/null 2>&1; then
  /opt/ci-venv/bin/python tools/generate_refs_index.py --format "$format" || true
else
  echo "[refs-index] PyYAML unavailable; skipping generation" >&2
fi

ls -lh docs/references-index.md dist/references-index.json || true
