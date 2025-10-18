#!/usr/bin/env bash
set -euo pipefail

# Guard that the CI image tag is not 'latest'; warn if missing to avoid drift.
# Inputs via environment:
#   INPUT_TAG: optional workflow_dispatch input value

input_tag="${INPUT_TAG:-}" || true

if [ "${input_tag}" = "latest" ]; then
  echo "Workflow input ci_image_tag must not be 'latest'. Use an immutable tag (e.g., YYYY.MM.DD-<sha> or vX.Y.Z)." >&2
  exit 1
fi

if [ -z "${input_tag}" ]; then
  echo "Note: ci_image_tag input not provided. Ensure repository variable CI_IMAGE_TAG is set to a pinned tag to avoid drift." >&2
fi
