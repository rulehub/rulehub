#!/usr/bin/env bash
set -euo pipefail

# Write a multi-line output to GITHUB_OUTPUT
# Usage: gha-write-output.sh <name> <file>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <name> <file>" >&2
  exit 2
fi

NAME="$1"
FILE="$2"

if [ ! -f "$FILE" ]; then
  echo "Error: file '$FILE' not found" >&2
  exit 1
fi

{
  echo "${NAME}<<EOF"
  cat "$FILE"
  echo 'EOF'
} >> "$GITHUB_OUTPUT"
