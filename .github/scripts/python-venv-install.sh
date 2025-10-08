#!/usr/bin/env bash
set -euo pipefail

# python-venv-install.sh
# Creates .venv, upgrades pip, and installs requirements (+dev) with
# compatibility shims for older Python versions when locks were generated on newer.

PYTHON_BIN="${PYTHON_BIN:-python}"
# Fallback to python3 if 'python' not present
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
fi

if [ ! -d .venv ]; then
  "${PYTHON_BIN}" -m venv .venv
fi

. .venv/bin/activate

# Under nektos/act, multiple jobs may run concurrently inside separate
# containers. Heavy pip installs across jobs can exhaust Docker's RW layer or
# memory and lead to exit 137 / "RWLayer unexpectedly nil". To keep ACT runs
# stable and fast, skip requirements installs entirely when ACT=true; individual
# steps can install tiny, targeted deps on demand (e.g., pyyaml, jsonschema).
if [ "${ACT:-}" = "true" ]; then
  echo "ACT=true detected; skipping requirements installs to reduce parallel load"
  echo "Python deps installed into .venv (no-op under ACT)"
  exit 0
fi

python -m pip install -U pip

# Shim for conditional deps when lock generated on newer Python
PY_VER=$(python - <<'EOF'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)
case "$PY_VER" in
  3.11|3.12)
    python -m pip install "typing-extensions==4.15.0" || true
    ;;
  3.13)
    # Most projects no longer need typing-extensions on 3.13, but include for safety if deps reference it.
    python -m pip install "typing-extensions==4.15.0" || true
    ;;
esac

if [ -f requirements.lock ]; then
  pip install -r requirements.lock
elif [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi

# Heuristic: if running under ACT (ACT=true) or common dev tools are already
# available system-wide (e.g., ruff), skip installing heavy dev requirements.
# This prevents concurrent jobs from all pulling large wheels (mkdocs, mypy,
# ruff, etc.) which can cause OOM or Docker RWLayer errors under ACT.
SKIP_DEV_INSTALL=0
if [ "${ACT:-}" = "true" ]; then
  SKIP_DEV_INSTALL=1
fi
if command -v ruff >/dev/null 2>&1; then
  SKIP_DEV_INSTALL=1
fi

if [ -f requirements-dev.lock ]; then
  if [ "$SKIP_DEV_INSTALL" = "1" ]; then
    echo "System-wide Python packages present (marker=ruff or ACT=true); skipping dev requirements install"
  else
    pip install -r requirements-dev.lock
  fi
elif [ -f requirements-dev.txt ]; then
  if [ "$SKIP_DEV_INSTALL" = "1" ]; then
    echo "System-wide Python packages present (marker=ruff or ACT=true); skipping dev requirements install"
  else
    pip install -r requirements-dev.txt
  fi
fi

echo "Python deps installed into .venv"
