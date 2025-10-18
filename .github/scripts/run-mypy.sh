#!/usr/bin/env bash
set -euo pipefail

# run-mypy.sh
# Purpose: centralized mypy invocation with a stable cache dir and version echo.
# CI images already include mypy in /opt/ci-venv (on PATH via python-venv-install).

export MYPY_CACHE_DIR=${MYPY_CACHE_DIR:-/tmp/mypy_cache}
mkdir -p "$MYPY_CACHE_DIR"

# Show mypy version (non-fatal if wrapper isn't available yet)
mypy --version || true

# Allow passing extra flags via MYPY_FLAGS if needed (kept minimal by default)
MYPY_FLAGS=${MYPY_FLAGS:-}

mypy --config-file mypy.ini ${MYPY_FLAGS}
