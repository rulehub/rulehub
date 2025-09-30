#!/usr/bin/env bash
set -euo pipefail

# Detect base/head SHAs from pull_request payload and decide whether to skip scanning.
# Outputs (via GITHUB_OUTPUT):
#   skip=true|false
#   base=<sha or empty>
#   head=<sha or empty>

skip=false
base=""
head=""

if [ -n "${GITHUB_EVENT_PATH-}" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
  if command -v jq >/dev/null 2>&1; then
    base=$(jq -r '.pull_request.base.sha // empty' "$GITHUB_EVENT_PATH" || true)
    head=$(jq -r '.pull_request.head.sha // empty' "$GITHUB_EVENT_PATH" || true)
  else
    base=$(grep -o '"base":{[^}]*}' -A2 "$GITHUB_EVENT_PATH" | grep -o '"sha":"[^"]*"' | head -1 | sed 's/"sha":"\([^"]*\)"/\1/' || true)
    head=$(grep -o '"head":{[^}]*}' -A2 "$GITHUB_EVENT_PATH" | grep -o '"sha":"[^"]*"' | head -1 | sed 's/"sha":"\([^"]*\)"/\1/' || true)
  fi
  if [ -n "$base" ] && [ -n "$head" ] && [ "$base" = "$head" ]; then
    skip=true
  fi
fi

{
  echo "skip=${skip}"
  echo "base=${base}"
  echo "head=${head}"
} >> "$GITHUB_OUTPUT"
