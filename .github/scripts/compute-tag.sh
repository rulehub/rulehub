#!/usr/bin/env bash
set -euo pipefail

# Compute a tag for publishing artifacts based on GitHub context.
# Writes "tag=<value>" to $GITHUB_OUTPUT if set, and also echoes the tag to stdout.
# Logic:
# - release event: use github.event.release.tag_name
# - branch main:   "main-<shortsha>"
# - otherwise:     "<shortsha>"

EVT_NAME="${GITHUB_EVENT_NAME:-${github_event_name:-}}"
REF_TYPE="${GITHUB_REF_TYPE:-${github_ref_type:-}}"
REF_NAME="${GITHUB_REF_NAME:-${github_ref_name:-}}"

# Obtain short SHA reliably
SHORT_SHA="${GITHUB_SHA:-}"
if [[ -z "$SHORT_SHA" || ${#SHORT_SHA} -lt 7 ]]; then
  if command -v git >/dev/null 2>&1; then
    SHORT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "")
  fi
fi

if [[ "$EVT_NAME" == "release" ]]; then
  TAG_NAME="${GITHUB_RELEASE_TAG_NAME:-${github_event_release_tag_name:-${GITHUB_REF_NAME:-}}}"
  # If env not propagated, try GITHUB_REF (refs/tags/vX.Y.Z)
  if [[ -z "$TAG_NAME" && -n "${GITHUB_REF:-}" ]]; then
    TAG_NAME="${GITHUB_REF##*/}"
  fi
  tag="$TAG_NAME"
elif [[ "$REF_TYPE" == "branch" && "$REF_NAME" == "main" ]]; then
  tag="main-${SHORT_SHA}"
else
  tag="${SHORT_SHA}"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "tag=${tag}" >> "$GITHUB_OUTPUT"
fi
echo "$tag"
