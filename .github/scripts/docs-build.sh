#!/usr/bin/env bash
set -euo pipefail

# Build MkDocs site in a reproducible way.
# - Uses python-venv-install helper from the CI base image to create .venv
# - If no docs requirements are tracked in the repo, falls back to installing
#   mkdocs + mkdocs-material into the venv (kept for portability; CI images
#   already include these in /opt/ci-venv so this typically becomes a no-op).
# - Prints mkdocs version and then performs a strict build.

# Strategy:
# 1) If requirements-docs.* is present, create/activate .venv and install those requirements.
# 2) Else, prefer baked MkDocs from /opt/ci-venv if present (fast path, zero installs).
# 3) Else, create/activate .venv and install mkdocs+material as minimal fallback.

MKDOCS_BIN=""

if [ -f requirements-docs.lock ] || [ -f requirements-docs.txt ]; then
  echo "[docs] docs requirements detected; preparing .venv and installing"
  python-venv-install
  . .venv/bin/activate
  if [ -f requirements-docs.lock ]; then
    pip install -r requirements-docs.lock
  else
    pip install -r requirements-docs.txt
  fi
  MKDOCS_BIN="mkdocs"
else
  if [ -x /opt/ci-venv/bin/mkdocs ]; then
    echo "[docs] using baked MkDocs from /opt/ci-venv (no installs)"
    MKDOCS_BIN="/opt/ci-venv/bin/mkdocs"
  else
    echo "[docs] docs requirements not found and baked MkDocs unavailable; creating .venv and installing minimal deps"
    python-venv-install
    . .venv/bin/activate
    pip install mkdocs mkdocs-material
    MKDOCS_BIN="mkdocs"
  fi
fi

echo "[docs] mkdocs version: $($MKDOCS_BIN --version || true)"
echo "[docs] building site (strict)"
$MKDOCS_BIN build --strict --verbose

echo "[docs] build complete"
