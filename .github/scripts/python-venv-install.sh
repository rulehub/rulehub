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

if [ -f requirements-dev.lock ]; then
  pip install -r requirements-dev.lock
elif [ -f requirements-dev.txt ]; then
  pip install -r requirements-dev.txt
fi

echo "Python deps installed into .venv"
