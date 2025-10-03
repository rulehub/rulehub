#!/usr/bin/env bash
set -euo pipefail

# Verify that requirements.lock and requirements-dev.lock are in sync with their source *.txt files.
# Regenerates into a temporary directory and diffs. Fails if differences are found.

TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "[lock-verify] Using pip-tools version:"; pip-compile --version || true

fail=0

# Normalize a lock file by stripping the volatile pip-compile header comments.
# This avoids diffs caused by temp output-file paths or default flags printed by pip-tools.
normalize_lock() {
  # Print from the first non-comment line to the end (drop leading '#' header block)
  # shellcheck disable=SC2016
  sed -n '/^[^#]/,$p' "$1" > "$2"
}

if [[ -f requirements.txt ]]; then
  echo "[lock-verify] Recompiling requirements.lock";
  pip-compile \
    --generate-hashes \
    --resolver=backtracking \
    --output-file "$TMP_DIR/requirements.lock" \
    requirements.txt >/dev/null
  # Compare normalized content to ignore header comment differences
  normalize_lock requirements.lock "$TMP_DIR/requirements.local.norm"
  normalize_lock "$TMP_DIR/requirements.lock" "$TMP_DIR/requirements.tmp.norm"
  if ! diff -u "$TMP_DIR/requirements.local.norm" "$TMP_DIR/requirements.tmp.norm" >/dev/null; then
    echo "[lock-verify] requirements.lock is OUT OF DATE" >&2
    diff -u "$TMP_DIR/requirements.local.norm" "$TMP_DIR/requirements.tmp.norm" || true
    fail=1
  else
    echo "[lock-verify] requirements.lock is up to date"
  fi
fi

if [[ -f requirements-dev.txt ]]; then
  echo "[lock-verify] Recompiling requirements-dev.lock";
  pip-compile \
    --allow-unsafe \
    --generate-hashes \
    --resolver=backtracking \
    --output-file "$TMP_DIR/requirements-dev.lock" \
    requirements-dev.txt >/dev/null
  normalize_lock requirements-dev.lock "$TMP_DIR/requirements-dev.local.norm"
  normalize_lock "$TMP_DIR/requirements-dev.lock" "$TMP_DIR/requirements-dev.tmp.norm"
  if ! diff -u "$TMP_DIR/requirements-dev.local.norm" "$TMP_DIR/requirements-dev.tmp.norm" >/dev/null; then
    echo "[lock-verify] requirements-dev.lock is OUT OF DATE" >&2
    diff -u "$TMP_DIR/requirements-dev.local.norm" "$TMP_DIR/requirements-dev.tmp.norm" || true
    fail=1
  else
    echo "[lock-verify] requirements-dev.lock is up to date"
  fi
fi

if [[ $fail -ne 0 ]]; then
  echo "[lock-verify] One or more lock files are stale. Run 'make lock lock-dev' and commit." >&2
  exit 2
fi

echo "[lock-verify] All lock files up to date."
