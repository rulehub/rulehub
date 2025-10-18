#!/usr/bin/env bash
set -euo pipefail

# Runs TruffleHog via Docker either on a git range or filesystem.
# Env:
#   BASE, HEAD (optional) - if both set, do git range scan
#   TRUFFLEHOG_VERSION - optional, default 3.74.0
#   TRUFFLEHOG_ALLOW_FAILURE - optional, default 0; if 1 pass --fail=false
#   TRUFFLEHOG_OUTPUT_JSON - optional, if set add --json and write output to this path

IMG="ghcr.io/trufflesecurity/trufflehog:${TRUFFLEHOG_VERSION:-3.74.0}"
echo "Using image ${IMG}"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "Docker not available; skipping TruffleHog scan." >&2
  exit 0
fi

# Build common flags
FAIL_FLAG="--fail"
if [ "${TRUFFLEHOG_ALLOW_FAILURE:-0}" = "1" ]; then
  FAIL_FLAG="--fail=false"
fi

JSON_FLAG=()
REDIRECT_OUT=""
if [ -n "${TRUFFLEHOG_OUTPUT_JSON:-}" ]; then
  JSON_FLAG=("--json")
  # shellcheck disable=SC2089
  REDIRECT_OUT="> \"${TRUFFLEHOG_OUTPUT_JSON}\""
fi

if [ -n "${BASE:-}" ] && [ -n "${HEAD:-}" ]; then
  echo "Scanning git range: ${BASE}..${HEAD}"
  git fetch --no-tags --prune --depth=0 origin || true
  # For git mode, repository path (.) comes last
  # Using eval only to support optional redirection when JSON output path provided
  set -x
  eval docker run --rm -v "$PWD:/repo" -w /repo "${IMG}" \
    git --no-update --results=verified,unknown "${FAIL_FLAG}" --since-commit "$BASE" --branch "$HEAD" . ${REDIRECT_OUT}
  set +x
else
  echo "Diff info unavailable; scanning working tree (filesystem)"
  # For filesystem mode, path should precede flags to avoid parsing issues in newer versions
  set -x
  eval docker run --rm -v "$PWD:/repo" -w /repo "${IMG}" \
    filesystem /repo --results=verified,unknown "${FAIL_FLAG}" ${JSON_FLAG:+"${JSON_FLAG[@]}"} ${REDIRECT_OUT}
  set +x
fi
