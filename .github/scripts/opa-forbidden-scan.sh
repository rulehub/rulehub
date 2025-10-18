#!/usr/bin/env bash
set -euo pipefail

# opa-forbidden-scan.sh — scan for disallowed boolean/membership negation patterns in Rego
# Usage: opa-forbidden-scan.sh [path]

DIR="${1:-policies}"

echo "Scanning for disallowed boolean patterns"
MATCHES=$(grep -R -nF -e "(not " -e "and not" -e "not (" "$DIR" || true)
if [ -n "$MATCHES" ]; then
  echo "$MATCHES" >&2
  echo "Found disallowed patterns" >&2
  exit 2
fi
echo "None"

echo "Scanning for ' not in {'"
MATCHES2=$(grep -R -nF ' not in {' "$DIR" || true)
if [ -n "$MATCHES2" ]; then
  echo "$MATCHES2" >&2
  echo "Found disallowed membership negation patterns" >&2
  exit 3
fi
echo "None"
