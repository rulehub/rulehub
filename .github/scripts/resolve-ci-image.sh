#!/usr/bin/env bash
set -euo pipefail

# Fallback resolver mirroring .github/actions/resolve-ci-image/action.yml
# Usage: bash .github/scripts/resolve-ci-image.sh [--kind policy|base|charts|frontend] [--tag <tag>]
# Outputs shell exports (IMAGE, TAG) and if GITHUB_OUTPUT set, writes image=<..> tag=<..>

kind="base"
input_tag=""

while [ $# -gt 0 ]; do
  case "$1" in
    --kind) kind="$2"; shift 2 ;;
    --tag) input_tag="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

case "$kind" in
  base|policy|charts|frontend) ;;
  *) echo "Unsupported kind: $kind (expected base|policy|charts|frontend)" >&2; exit 2 ;;
esac

tag="$input_tag"
if [ -z "$tag" ] && [ -n "${CI_IMAGE_TAG:-}" ]; then
  tag="$CI_IMAGE_TAG"
fi
if [ -z "$tag" ]; then
  tag="latest"
fi

owner="${GITHUB_REPOSITORY_OWNER:-${OWNER:-}}"
if [ -z "$owner" ]; then
  echo "Missing owner (GITHUB_REPOSITORY_OWNER)" >&2
  exit 3
fi

image="ghcr.io/${owner}/ci-${kind}:${tag}"
echo "Resolved CI image: $image" >&2

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "image=$image" >> "$GITHUB_OUTPUT"
  echo "tag=$tag" >> "$GITHUB_OUTPUT"
fi

export IMAGE_REF="$image"
export IMAGE_TAG="$tag"
