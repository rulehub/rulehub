#!/usr/bin/env bash
set -euo pipefail

# python-venv-install.sh
# Unified venv helper for CI/ACT:
# - Under ACT: prefer reusing pre-baked /opt/ci-venv (symlink .venv) and skip installs
# - On CI: if an image-provided python-venv-install exists, delegate to it; otherwise do a minimal compatible install here

PYTHON_BIN="${PYTHON_BIN:-python3}"

# Fast path for ACT to avoid pip/ensurepip edge cases and heavy IO
if [ "${ACT:-}" = "true" ]; then
  if [ ! -e .venv ] && [ -d /opt/ci-venv ] && [ -f /opt/ci-venv/bin/activate ]; then
    echo "ACT=true and /opt/ci-venv present; linking .venv -> /opt/ci-venv"
    ln -s /opt/ci-venv .venv
    echo "Python venv prepared at .venv (linked)"
    exit 0
  fi
  # Create a minimal venv with the selected interpreter and skip installs
  if [ ! -d .venv ]; then
    "$PYTHON_BIN" -m venv .venv
  fi
  # Some upstream python base images omit pip inside freshly created venvs.
  # Ensure pip exists to allow downstream scripts (python-ensure-and-run.sh) to install minimal deps under ACT.
  if [ ! -x .venv/bin/pip ]; then
    echo "pip not found in .venv; bootstrapping via ensurepip"
    .venv/bin/python -m ensurepip --upgrade || true
    # Fallback: try get-pip if ensurepip is unavailable (rare in Debian Slim variants)
    if [ ! -x .venv/bin/pip ]; then
      python - <<'PY' || true
import sys, urllib.request, subprocess, os
url = 'https://bootstrap.pypa.io/get-pip.py'
dst = 'get-pip.py'
try:
    with urllib.request.urlopen(url, timeout=20) as r, open(dst, 'wb') as f:
        f.write(r.read())
    subprocess.run([os.path.abspath('.venv/bin/python'), dst, '--upgrade'], check=False)
finally:
    try:
        os.remove(dst)
    except Exception:
        pass
PY
    fi
  fi
  echo "ACT=true; created minimal .venv with $PYTHON_BIN (skipping pip installs)"
  exit 0
fi

# Delegate to image-provided installer if available
if command -v python-venv-install >/dev/null 2>&1; then
  exec python-venv-install
fi

# Fallback: lightweight local venv + optional installs
if [ ! -d .venv ]; then
  "$PYTHON_BIN" -m venv .venv
fi
. .venv/bin/activate

python -m pip install -U pip

PY_VER=$(python - <<'EOF'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)
case "$PY_VER" in
  3.11|3.12)
    python -m pip install "typing-extensions==4.15.0" || true
    ;;
esac

if [ -f requirements.lock ]; then
  pip install -r requirements.lock
elif [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi

if [ -f requirements-dev.lock ]; then
  pip install -r requirements-dev.lock || true
elif [ -f requirements-dev.txt ]; then
  pip install -r requirements-dev.txt || true
fi

echo "Python deps installed into .venv"
