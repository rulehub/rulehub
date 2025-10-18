#!/usr/bin/env bash
set -euo pipefail

# probe-image-pull.sh
# Usage: PROBE_IMAGE=<image-ref> ./probe-image-pull.sh
# Emits 'can_pull=true|false' to stdout for easy use with GitHub Actions $GITHUB_OUTPUT.

IMAGE_REF="${PROBE_IMAGE:-${1-}}"
if [[ -z "${IMAGE_REF}" ]]; then
  echo "error: PROBE_IMAGE not set and no image ref provided as first arg" >&2
  exit 2
fi

echo "Probing anonymous pull for ${IMAGE_REF}"
# If image already present, skip pulling to save time
if docker image inspect "${IMAGE_REF}" >/dev/null 2>&1; then
  echo "Image already present locally; skipping pull."
  echo "can_pull=true"
  exit 0
fi

if command -v timeout >/dev/null 2>&1; then
  if timeout 120s docker pull "${IMAGE_REF}"; then
    echo "can_pull=true"
  else
    echo "can_pull=false"
  fi
elif docker pull "${IMAGE_REF}"; then
  echo "can_pull=true"
else
  echo "can_pull=false"
fi
