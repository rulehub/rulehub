#!/usr/bin/env bash
set -euo pipefail

bundle=dist/opa-bundle.tar.gz
mkdir -p dist
if [ ! -s "$bundle" ]; then
  echo "Bundle $bundle missing" >&2
  exit 1
fi

if command -v syft >/dev/null 2>&1; then
  # Prefer new 'scan' command; fallback to legacy 'packages'
  if syft scan --help >/dev/null 2>&1; then
    syft scan file:"$bundle" -o cyclonedx-json > dist/opa-bundle.sbom.cdx.json
    echo "CycloneDX SBOM generated (scan)" >&2
    syft scan file:"$bundle" -o spdx-json > dist/opa-bundle.sbom.spdx.json
    echo "SPDX SBOM generated (scan)" >&2
  else
    syft packages file:"$bundle" -o cyclonedx-json > dist/opa-bundle.sbom.cdx.json
    echo "CycloneDX SBOM generated (packages legacy)" >&2
    syft packages file:"$bundle" -o spdx-json > dist/opa-bundle.sbom.spdx.json
    echo "SPDX SBOM generated (packages legacy)" >&2
  fi
else
  echo "syft not available; skipping SBOMs" >&2
fi
