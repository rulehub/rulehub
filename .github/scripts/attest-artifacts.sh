#!/usr/bin/env bash
set -euo pipefail

# Create attestations (SBOMs, optionally others) using cosign attest.
# Skips if SKIP_SUPPLYCHAIN=1 or cosign unavailable.

if [ "${SKIP_SUPPLYCHAIN:-0}" = "1" ]; then
  echo "[attest-artifacts] SKIP_SUPPLYCHAIN=1 -> skipping attestation" >&2
  exit 0
fi

if ! command -v cosign >/dev/null 2>&1; then
  echo "[attest-artifacts] cosign not found; skipping" >&2
  exit 0
fi

if [ -z "${IMAGE:-}" ] || [ -z "${TAG:-}" ]; then
  echo "[attest-artifacts] IMAGE and TAG env required" >&2
  exit 1
fi

ref="${IMAGE}:${TAG}"
COSIGN_EXPERIMENTAL=1
export COSIGN_EXPERIMENTAL
COSIGN_YES=1
export COSIGN_YES

# Attest SBOMs
if [ -s dist/opa-bundle.sbom.cdx.json ]; then
  echo "[attest-artifacts] Attesting CycloneDX SBOM" >&2
  cosign attest --yes --predicate dist/opa-bundle.sbom.cdx.json --type cyclonedx "$ref"
fi
if [ -s dist/opa-bundle.sbom.spdx.json ]; then
  echo "[attest-artifacts] Attesting SPDX SBOM" >&2
  cosign attest --yes --predicate dist/opa-bundle.sbom.spdx.json --type spdx "$ref"
fi

echo "[attest-artifacts] Done" >&2
