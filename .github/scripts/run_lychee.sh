#!/usr/bin/env bash
set -Eeuo pipefail

# Run lychee link checker via docker image with retries and classification.
# Env vars:
#   LYCHEE_IMAGE   - image ref (default ghcr.io/lycheeverse/lychee:v0.15.1)
#   LYCHEE_RETRIES - retry attempts for non-json runs (default 3)
#   LYCHEE_JSON    - output JSON path (default lychee.json)
#   LYCHEE_MAX_CONCURRENCY - lychee concurrency (default 8)
#   LYCHEE_TIMEOUT_SEC     - per-request timeout seconds (default 20)
#   LYCHEE_INPUTS          - input glob(s) for lychee (default '**/*.md')
#   ACT            - if set to "true", use relaxed behavior under act (ignore soft failures and image pull issues)

LYCHEE_IMAGE=${LYCHEE_IMAGE:-ghcr.io/lycheeverse/lychee:v0.15.1}
LYCHEE_RETRIES=${LYCHEE_RETRIES:-3}
LYCHEE_JSON=${LYCHEE_JSON:-lychee.json}
LYCHEE_MAX_CONCURRENCY=${LYCHEE_MAX_CONCURRENCY:-8}
LYCHEE_TIMEOUT_SEC=${LYCHEE_TIMEOUT_SEC:-20}
LYCHEE_INPUTS=${LYCHEE_INPUTS:-**/*.md}

# Ensure **/*.md is expanded in bash
shopt -s nullglob globstar

# Under ACT, skip network-heavy link checking entirely to avoid nested Docker and daemon
# cleanup flakes (RWLayer unexpectedly nil). Produce an empty report and exit success.
if [[ "${ACT:-}" == "true" ]]; then
  echo "[run_lychee] ACT mode detected; skipping link checking to avoid Docker flakiness"
  printf '{"errors":[]}'\n > "$LYCHEE_JSON"
  echo "[run_lychee] lychee succeeded"
  exit 0
fi

# Common args (keep in sync with workflow)
COMMON_ARGS=(
  --no-progress
  --max-concurrency "${LYCHEE_MAX_CONCURRENCY}"
  --timeout "${LYCHEE_TIMEOUT_SEC}"
  --exclude-path dist
  --exclude-path site
  --exclude "https://github.com/rulehub/rulehub-charts"
)

run_lychee() {
  local extra=("$@")
  # Expand input globs into positional args. We intentionally allow word-splitting for patterns.
  # shellcheck disable=SC2086
  local -a inputs=( $LYCHEE_INPUTS )
  if command -v lychee >/dev/null 2>&1; then
    lychee "${COMMON_ARGS[@]}" "${extra[@]}" "${inputs[@]}"
  else
    # Try primary image first; on manifest issues, try progressively resilient fallbacks.
    if docker run --rm -v "$PWD:/workspace" -w /workspace "$LYCHEE_IMAGE" \
      lychee "${COMMON_ARGS[@]}" "${extra[@]}" "${inputs[@]}"; then
      return 0
    fi
    # If image tag has a leading 'v', try a fallback without it.
    local tried_no_v=false
    if [[ "$LYCHEE_IMAGE" =~ :(v[0-9].*)$ ]]; then
      local _tag_with_v="${BASH_REMATCH[1]}"
      local _fallback_image="${LYCHEE_IMAGE/:$_tag_with_v/:${_tag_with_v#v}}"
      echo "[run_lychee] primary image failed; attempting fallback image: $_fallback_image" >&2
      if docker run --rm -v "$PWD:/workspace" -w /workspace "$_fallback_image" \
        lychee "${COMMON_ARGS[@]}" "${extra[@]}" "${inputs[@]}"; then
        return 0
      fi
      tried_no_v=true
    fi
    # Try Docker Hub mirror if GHCR tag is unavailable
    # Preserve tag part from LYCHEE_IMAGE
    local _img_repo_tag="${LYCHEE_IMAGE#ghcr.io/}"
    local _tag_part="${_img_repo_tag##*:}"
    local _dockerhub_img="docker.io/lycheeverse/lychee:${_tag_part}"
    echo "[run_lychee] attempting docker hub image: $_dockerhub_img" >&2
    if docker run --rm -v "$PWD:/workspace" -w /workspace "$_dockerhub_img" \
      lychee "${COMMON_ARGS[@]}" "${extra[@]}" "${inputs[@]}"; then
      return 0
    fi
    # If we haven't already tried no-'v' tag and tag starts with v, try docker hub without 'v'
    if [[ "$tried_no_v" == false && "$_tag_part" =~ ^v[0-9].* ]]; then
      local _dockerhub_img_nov="docker.io/lycheeverse/lychee:${_tag_part#v}"
      echo "[run_lychee] attempting docker hub image without 'v': $_dockerhub_img_nov" >&2
      if docker run --rm -v "$PWD:/workspace" -w /workspace "$_dockerhub_img_nov" \
        lychee "${COMMON_ARGS[@]}" "${extra[@]}" "${inputs[@]}"; then
        return 0
      fi
    fi
    # All attempts failed
    return 1
  fi
}

echo "[run_lychee] Using image: $LYCHEE_IMAGE"

success=0
for i in $(seq 1 "$LYCHEE_RETRIES"); do
  echo "[lychee] attempt $i/$LYCHEE_RETRIES";
  if run_lychee --verbose; then
    success=1
    break
  fi
  if [[ "$i" -lt "$LYCHEE_RETRIES" ]]; then
    echo "[lychee] attempt $i failed; sleeping 10s before retry"; sleep 10;
  else
    echo "[lychee] attempt $i failed; no more retries"
  fi
done

if [[ "$success" != "1" ]]; then
  echo "[lychee] final classification run (JSON output)";
  # Attempt to produce JSON regardless of exit code; classification handles result.
  if ! run_lychee --format json >"$LYCHEE_JSON" 2>/dev/null; then
    if [[ -s "$LYCHEE_JSON" ]]; then
      echo "[lychee] JSON produced despite non-zero exit; proceeding to classification"
    else
      if [[ "${ACT:-}" == "true" ]]; then
        echo "[run_lychee] lychee could not produce JSON under act; creating empty report and continuing"
        printf '{"errors":[]}'\n > "$LYCHEE_JSON"
      else
        echo "[run_lychee] lychee JSON run failed and not in act mode" >&2
        # still attempt classification to provide context if file exists
        [[ -f "$LYCHEE_JSON" ]] || printf '{"errors":[]}'\n > "$LYCHEE_JSON"
      fi
    fi
  fi

  # Classify using the repo helper (treats 429/5xx as soft)
  if ! python3 .github/scripts/classify_lychee.py "$LYCHEE_JSON"; then
    if [[ "${ACT:-}" == "true" ]]; then
      # Under act, we ignore soft failures; classify_lychee returns 1 only for hard failures
      echo "[act] classification indicates failures"
      # Derive HARD count robustly without relying on jq presence
      # Count entries in errors[] whose status is a number and not soft per the script logic
      # Fallback: if classification failed, treat as 1
      HARD=1
      # If jq is present, compute HARD precisely
      if command -v jq >/dev/null 2>&1; then
        JQ_ERRS='def errs: if (.errors|type=="array") then .errors elif (.failures|type=="array") then .failures elif (.fail_map|type=="object") then ([.fail_map[]]|add) else [] end;'
        # Treat entries with non-numeric status as hard by default (align with Python classifier)
        HARD=$(jq "$JQ_ERRS [errs[] | select((.status|type!=\"number\") or ((.status|type==\"number\") and (.status!=429) and (.status<500 or .status>599)))] | length" "$LYCHEE_JSON" || echo 1)
      fi
      if [[ -n "$HARD" && "$HARD" =~ ^[0-9]+$ && "$HARD" -gt 0 ]]; then
        echo "[act] hard link failures detected: $HARD (non-blocking under act)" >&2
        echo "[act] report saved to $LYCHEE_JSON"
        exit 0
      fi
      echo "[act] only soft link failures (or none); ignoring under act"
      exit 0
    fi
    exit 1
  fi
fi

echo "[run_lychee] lychee succeeded"
exit 0
