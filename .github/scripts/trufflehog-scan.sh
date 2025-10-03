#!/usr/bin/env bash
set -euo pipefail

# Runs TruffleHog via Docker either on a git range or filesystem.
# Env:
#   BASE, HEAD (optional) - if both set, do git range scan
#   TRUFFLEHOG_VERSION - optional, default 3.74.0

IMG="ghcr.io/trufflesecurity/trufflehog:${TRUFFLEHOG_VERSION:-3.74.0}"
echo "Using image ${IMG}"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "Docker not available; skipping TruffleHog scan." >&2
  exit 0
fi

if [ -n "${BASE:-}" ] && [ -n "${HEAD:-}" ]; then
  echo "Scanning git range: ${BASE}..${HEAD}"
  git fetch --no-tags --prune --depth=0 origin || true
  docker run --rm -v "$PWD:/repo" -w /repo "${IMG}" \
    git --no-update --results=verified,unknown --fail --since-commit "$BASE" --branch "$HEAD" .
else
  echo "Diff info unavailable; scanning working tree (filesystem)"
  docker run --rm -v "$PWD:/repo" -w /repo "${IMG}" \
    filesystem --results=verified,unknown --fail /repo
fi
