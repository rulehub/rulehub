#!/usr/bin/env bash
set -euo pipefail

# Verify signatures of artifacts using cosign verify-blob.
# Skips if SKIP_SUPPLYCHAIN=1 or cosign unavailable.

if [ "${SKIP_SUPPLYCHAIN:-0}" = "1" ]; then
  echo "[verify-signatures] SKIP_SUPPLYCHAIN=1 -> skipping" >&2
  exit 0
fi

if ! command -v cosign >/dev/null 2>&1; then
  echo "[verify-signatures] cosign not found; skipping" >&2
  exit 0
fi

COSIGN_EXPERIMENTAL=1
export COSIGN_EXPERIMENTAL

artifacts=(
  dist/opa-bundle.tar.gz
  dist/opa-bundle.manifest.json
  dist/opa-bundle.sbom.cdx.json
  dist/opa-bundle.sbom.spdx.json
)

fail=0
for base in "${artifacts[@]}"; do
  sig="${base}.sig"; cert="${base}.cert"
  if [ ! -s "$base" ]; then
    echo "[verify-signatures] Missing artifact $base" >&2; fail=1; continue
  fi
  if [ ! -s "$sig" ] || [ ! -s "$cert" ]; then
    echo "[verify-signatures] Missing signature or certificate for $base" >&2; fail=1; continue
  fi
  echo "[verify-signatures] Verifying $base" >&2
  cosign verify-blob \
    --certificate "$cert" \
    --signature "$sig" \
    --certificate-identity-regexp "https://github.com/${GITHUB_REPOSITORY}/.*" \
    --certificate-oidc-issuer-regexp '^https://token.actions.githubusercontent.com$' \
    "$base" >/dev/null
done

exit $fail
