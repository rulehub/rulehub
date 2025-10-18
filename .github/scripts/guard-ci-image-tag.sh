#!/usr/bin/env bash
# Enforce non-latest, pinned CI image tag usage in workflows.
# Usage: guard-ci-image-tag.sh <input_tag>
set -euo pipefail

INPUT_TAG="${1:-}"
ENV_TAG="${CI_IMAGE_TAG:-}"

# Detect act environment reliably: ACT/IS_ACT flags or workspace path pattern
is_act_env() {
  if [[ "${ACT:-}" == "true" || "${IS_ACT:-}" == "true" ]]; then
    return 0
  fi
  case "${GITHUB_WORKSPACE:-}" in
    /github/*) return 0 ;;
  esac
  return 1
}

ACT_MODE=false
if is_act_env; then ACT_MODE=true; fi

# Valid immutable tag patterns:
#  - SemVer: vMAJOR.MINOR.PATCH with optional pre-release/build (e.g., v1.2.3, v1.2.3-rc.1)
#  - Date-SHA: YYYY.MM.DD-<hexsha> (e.g., 2025.10.14-deadbeef)
is_valid_immutable_tag() {
  local tag="$1"
  [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z]+)*$ ]] && return 0
  [[ "$tag" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9a-f]{7,40}$ ]] && return 0
  return 1
}

# Always block explicit 'latest' unless running under act (dev/local convenience)
if [[ "${INPUT_TAG}" == "latest" ]]; then
  if [[ "$ACT_MODE" == true ]]; then
    echo "Note: ci_image_tag input is 'latest' (allowed under act); prefer immutable tag for CI." >&2
    exit 0
  fi
  echo "Workflow input ci_image_tag must not be 'latest'. Use an immutable tag (e.g., 2025.10.03-<sha> or vX.Y.Z)." >&2
  exit 1
fi

# If input tag provided (non-empty and not 'latest'), validate it unless allowed in act
if [[ -n "${INPUT_TAG}" ]]; then
  if [[ "$ACT_MODE" == true && ( "${INPUT_TAG}" == "dev-local" || "${INPUT_TAG}" == "latest" ) ]]; then
    echo "Note: ci_image_tag='${INPUT_TAG}' allowed under act (dev/local)." >&2
    exit 0
  fi
  if ! is_valid_immutable_tag "${INPUT_TAG}"; then
    echo "ci_image_tag='${INPUT_TAG}' is not an accepted immutable tag. Use 'vMAJOR.MINOR.PATCH' or 'YYYY.MM.DD-<sha>'." >&2
    exit 1
  fi
  # Valid input provided; accept
  exit 0
fi

# If input is empty, enforce presence of CI_IMAGE_TAG (non-latest) in real CI; relax under act
if [[ -z "${INPUT_TAG}" ]]; then
  if [[ "$ACT_MODE" == true ]]; then
    # Under act, allow empty input; common flows rely on dev-local images
    if [[ -z "${ENV_TAG}" ]]; then
      echo "Note: ci_image_tag input not provided. Under act, proceeding without a pinned tag (dev/local)." >&2
      exit 0
    fi
    if [[ "${ENV_TAG}" == "latest" ]]; then
      echo "Note: CI_IMAGE_TAG is 'latest' (allowed under act); prefer immutable tag for CI." >&2
      exit 0
    fi
    # Allow 'dev-local' under act
    if [[ "${ENV_TAG}" == dev-local ]]; then
      echo "Note: CI_IMAGE_TAG is 'dev-local' (allowed under act)." >&2
      exit 0
    fi
    # Otherwise note validity under act
    if is_valid_immutable_tag "${ENV_TAG}"; then
      echo "Note: ci_image_tag input not provided. Using CI_IMAGE_TAG='${ENV_TAG}'." >&2
    else
      echo "Note: ci_image_tag input not provided and CI_IMAGE_TAG='${ENV_TAG}' does not match immutable patterns; allowed under act but should be corrected for CI." >&2
    fi
    exit 0
  fi

  # Real GitHub Actions: require CI_IMAGE_TAG and disallow 'latest'
  if [[ -z "${ENV_TAG}" ]]; then
    echo "ci_image_tag input not provided and CI_IMAGE_TAG is unset. Set repository/org variable CI_IMAGE_TAG to an immutable tag to avoid drift." >&2
    exit 1
  fi
  if [[ "${ENV_TAG}" == "latest" ]]; then
    echo "CI_IMAGE_TAG must not be 'latest'. Use an immutable tag (e.g., 2025.10.03-<sha> or vX.Y.Z)." >&2
    exit 1
  fi
  # Require immutable format in real CI
  if ! is_valid_immutable_tag "${ENV_TAG}"; then
    echo "CI_IMAGE_TAG='${ENV_TAG}' is not an accepted immutable tag. Use 'vMAJOR.MINOR.PATCH' or 'YYYY.MM.DD-<sha>'." >&2
    exit 1
  fi
  echo "Using CI_IMAGE_TAG='${ENV_TAG}'." >&2
fi

exit 0
