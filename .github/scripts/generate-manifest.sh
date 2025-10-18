#!/usr/bin/env bash
set -euo pipefail

out=${1:-dist/opa-bundle.manifest.json}
mkdir -p dist

# Prefer existing venv
if [ -x .venv/bin/python ]; then
  . .venv/bin/activate
fi

python tools/generate_bundle_manifest.py --output "$out" --exclude-tests
head -n 30 "$out" || true
