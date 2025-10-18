#!/usr/bin/env bash
set -euo pipefail

# Runs Checkov via a pinned container digest and produces SARIF output at checkov.sarif.
# Env:
#   CHECKOV_IMAGE_DIGEST: required (sha256:...). Refuse to use tags.
#   ACT: optional flag used to allow no-op under act when digest is not provided.
#   REPO: optional image repository (default bridgecrew/checkov)

REPO=${REPO:-bridgecrew/checkov}

if [[ -z "${CHECKOV_IMAGE_DIGEST:-}" ]]; then
  if [[ "${ACT:-}" == "true" ]]; then
    echo "[act] CHECKOV_IMAGE_DIGEST not provided; skipping Checkov scan under act (no network pulls)." >&2
    echo "Hint: provide via repository Variables, or pass to act with --secret-file (CHECKOV_IMAGE_DIGEST=sha256:<digest>) or --env CHECKOV_IMAGE_DIGEST=sha256:<digest> to enable the scan locally." >&2
    exit 0
  fi
  echo "ERROR: CHECKOV_IMAGE_DIGEST is required (sha256:...) and must be pinned; refusing to use ':latest'." >&2
  exit 1
fi

IMG="${REPO}@${CHECKOV_IMAGE_DIGEST}"

docker run --rm \
  -v "${PWD}:/workspace" -w /workspace \
  "${IMG}" \
  checkov -d . --framework kubernetes \
  --skip-path tests/kyverno --skip-path tests/gatekeeper \
  --output sarif --output-file-path checkov.sarif \
  --quiet || true
