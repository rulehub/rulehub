#!/usr/bin/env bash
# Probe anonymous pull capability for a docker image ref and set can_pull on GITHUB_OUTPUT.
# Usage: ghcr-probe.sh <image_ref>
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <image_ref>" >&2
  exit 2
fi

IMAGE_REF="$1"

echo "Probing anonymous pull for ${IMAGE_REF}"

# If present locally, consider pullable without network
if docker image inspect "${IMAGE_REF}" >/dev/null 2>&1; then
  echo "Image present locally; skipping pull"
  echo "can_pull=true" >>"${GITHUB_OUTPUT:-/dev/null}" || true
  exit 0
fi

# Time-bound docker pull to avoid hangs
pull_cmd=(docker pull "${IMAGE_REF}")
AUTHPULLED=false
if command -v timeout >/dev/null 2>&1; then
  if timeout 120s "${pull_cmd[@]}"; then
    echo "can_pull=true" >>"${GITHUB_OUTPUT:-/dev/null}" || true
    exit 0
  fi
else
  if "${pull_cmd[@]}"; then
    echo "can_pull=true" >>"${GITHUB_OUTPUT:-/dev/null}" || true
    exit 0
  fi
fi

# Try authenticated pull using GitHub actor/token if available (GitHub-hosted runners)
if [[ -n "${GITHUB_TOKEN:-}" && -n "${GITHUB_ACTOR:-}" ]]; then
  echo "Anonymous pull failed; attempting authenticated pull to ghcr.io as ${GITHUB_ACTOR}" >&2
  if docker login ghcr.io -u "${GITHUB_ACTOR}" -p "${GITHUB_TOKEN}" >/dev/null 2>&1; then
    if command -v timeout >/dev/null 2>&1; then
      timeout 120s docker pull "${IMAGE_REF}" >/dev/null 2>&1 && AUTHPULLED=true || AUTHPULLED=false
    else
      docker pull "${IMAGE_REF}" >/dev/null 2>&1 && AUTHPULLED=true || AUTHPULLED=false
    fi
    docker logout ghcr.io >/dev/null 2>&1 || true
  fi
fi

if [[ "$AUTHPULLED" == "true" ]]; then
  echo "can_pull=true" >>"${GITHUB_OUTPUT:-/dev/null}" || true
else
  echo "can_pull=false" >>"${GITHUB_OUTPUT:-/dev/null}" || true
fi
