#!/usr/bin/env bash
set -euo pipefail

# Verify internal integrity: manifest vs bundle, presence of core files.
# Delegates deep cryptographic checks to Python tool if available.

MANIFEST=dist/opa-bundle.manifest.json
BUNDLE=dist/opa-bundle.tar.gz

if [ ! -s "$MANIFEST" ] || [ ! -s "$BUNDLE" ]; then
  echo "[verify-integrity] Missing manifest or bundle" >&2
  exit 1
fi

if command -v python >/dev/null 2>&1 && [ -f tools/verify_bundle.py ]; then
  echo "[verify-integrity] Running Python verifier" >&2
  python tools/verify_bundle.py --manifest "$MANIFEST" --bundle "$BUNDLE" --policies-root policies --skip-git
else
  echo "[verify-integrity] Python verifier not available; performing minimal hash presence checks" >&2
  jq -e '.aggregate_hash' "$MANIFEST" >/dev/null 2>&1 || { echo "aggregate_hash missing" >&2; exit 1; }
fi

echo "[verify-integrity] OK" >&2
