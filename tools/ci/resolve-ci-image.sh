#!/usr/bin/env bash
set -euo pipefail

# Resolve the CI image reference and tag, emitting via GitHub Actions output file.
# Env:
#   INPUT_TAG: workflow input
#   VARS_TAG: repository/org variable
#   CI_IMAGE_TAG: env or act-injected tag
#   GITHUB_OUTPUT: file to write outputs (handled by GH/act)

tag="${INPUT_TAG:-}"
if [ -z "${tag}" ] && [ -n "${VARS_TAG:-}" ]; then
  tag="${VARS_TAG}"
fi
if [ -z "${tag}" ] && [ -n "${CI_IMAGE_TAG:-}" ]; then
  tag="${CI_IMAGE_TAG}"
fi

if [ -z "${tag}" ]; then
  echo "ERROR: No CI image tag provided. Set workflow input ci_image_tag or repository/org variable CI_IMAGE_TAG." >&2
  exit 1
fi

image_ref="ghcr.io/rulehub/ci-base:${tag}"
{
  echo "image=${image_ref}"
  echo "tag=${tag}"
} >> "${GITHUB_OUTPUT}"
