#!/usr/bin/env bash
set -euo pipefail

# Sign core artifacts (bundle, manifest, SBOMs) using keyless Cosign.
# Requirements: cosign in PATH, OIDC available (on GitHub Actions), files pre-built in dist/.
# Skips automatically if SKIP_SUPPLYCHAIN=1 or cosign unavailable.

if [ "${SKIP_SUPPLYCHAIN:-0}" = "1" ]; then
  echo "[sign-artifacts] SKIP_SUPPLYCHAIN=1 -> skipping signing" >&2
  exit 0
fi

if ! command -v cosign >/dev/null 2>&1; then
  echo "[sign-artifacts] cosign not found; skipping" >&2
  exit 0
fi

COSIGN_EXPERIMENTAL=1
export COSIGN_EXPERIMENTAL
COSIGN_YES=1
export COSIGN_YES

artifacts=(
  dist/opa-bundle.tar.gz
  dist/opa-bundle.manifest.json
  dist/opa-bundle.sbom.cdx.json
  dist/opa-bundle.sbom.spdx.json
)

status=0
for f in "${artifacts[@]}"; do
  if [ ! -s "$f" ]; then
    echo "[sign-artifacts] Missing artifact $f" >&2
    status=1
    continue
  fi
  base="$f"
  sig="${base}.sig"
  cert="${base}.cert"
  echo "[sign-artifacts] Signing $base" >&2
  cosign sign-blob --yes \
    --output-signature "$sig" \
    --output-certificate "$cert" \
    "$base"
  # Immediate self-verify (defense in depth before push)
  echo "[sign-artifacts] Verifying signature for $base" >&2
  cosign verify-blob \
    --certificate "$cert" \
    --signature "$sig" \
    --certificate-identity-regexp "https://github.com/${GITHUB_REPOSITORY}/.*" \
    --certificate-oidc-issuer-regexp '^https://token.actions.githubusercontent.com$' \
    "$base" >/dev/null
done

exit $status
