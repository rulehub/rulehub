#!/usr/bin/env bash
# Enforce non-latest, pinned CI image tag usage in workflows.
# Usage: guard-ci-image-tag.sh <input_tag>
set -euo pipefail

INPUT_TAG="${1:-}"

if [[ "${INPUT_TAG}" == "latest" ]]; then
  echo "Workflow input ci_image_tag must not be 'latest'. Use an immutable tag (e.g., 2025.10.03-<sha> or vX.Y.Z)." >&2
  exit 1
fi

if [[ -z "${INPUT_TAG}" ]]; then
  echo "Note: ci_image_tag input not provided. Ensure repository variable CI_IMAGE_TAG is set to a pinned tag to avoid drift." >&2
fi

exit 0
