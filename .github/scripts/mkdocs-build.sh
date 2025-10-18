#!/usr/bin/env bash
set -euo pipefail

# Build MkDocs site in a strict, reproducible way.
# Strategy:
# 1) If requirements-docs.* present: create/activate .venv, install those requirements, run mkdocs from venv.
# 2) Else prefer baked MkDocs from /opt/ci-venv if present (no installs), falling back to PATH mkdocs.

MK=""

if [ -f requirements-docs.lock ] || [ -f requirements-docs.txt ]; then
  echo "[docs] docs requirements detected; preparing .venv and installing"
  if command -v python-venv-install >/dev/null 2>&1; then
    python-venv-install
  else
    python3 -m venv .venv
  fi
  # shellcheck source=/dev/null
  . .venv/bin/activate
  if [ -f requirements-docs.lock ]; then
    pip install -r requirements-docs.lock
  else
    pip install -r requirements-docs.txt
  fi
  MK=mkdocs
else
  if [ -x /opt/ci-venv/bin/mkdocs ]; then
    echo "[docs] using baked MkDocs from /opt/ci-venv (no installs)"
    MK=/opt/ci-venv/bin/mkdocs
    export PATH=/opt/ci-venv/bin:$PATH
  elif command -v mkdocs >/dev/null 2>&1; then
    MK=mkdocs
  else
    echo "mkdocs not found in PATH or /opt/ci-venv/bin" >&2
    exit 127
  fi
fi

"$MK" --version
"$MK" build --strict --verbose
