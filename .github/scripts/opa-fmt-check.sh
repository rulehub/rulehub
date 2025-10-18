#!/usr/bin/env bash
set -euo pipefail

# opa-fmt-check.sh — check Rego formatting and show diffs; exit 4 if changes needed
# Usage: opa-fmt-check.sh [path]

DIR="${1:-policies}"

CHANGED=$(opa fmt -l "$DIR" || true)
if [ -n "$CHANGED" ]; then
  echo "Rego files require formatting:" >&2
  echo "$CHANGED" >&2
  for f in $CHANGED; do
    echo "--- fmt diff for: $f" >&2
    opa fmt -d "$f" || true
  done
  exit 4
fi
echo "Formatting OK"
