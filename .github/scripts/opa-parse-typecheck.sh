#!/usr/bin/env bash
set -euo pipefail

# opa-parse-typecheck.sh — run OPA parse & type check on a directory (default: policies)
# Usage: opa-parse-typecheck.sh [path]

DIR="${1:-policies}"

opa check "$DIR"
