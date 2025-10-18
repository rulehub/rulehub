#!/usr/bin/env bash
# Ensure minimal Python dependencies are present, then run the given command.
# Usage: python-ensure-and-run.sh "import modA, modB" <cmd...>
# Example: python-ensure-and-run.sh "import yaml, jsonschema" python tools/validate_metadata.py
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 \"import <modules comma/space separated>\" <command...>" >&2
  exit 2
fi

IMPORTS="$1"; shift

# If a venv exists, activate it to avoid polluting system. Prefer baked /opt/ci-venv if no .venv yet.
if [[ -d .venv ]]; then
  # shellcheck source=/dev/null
  source .venv/bin/activate || true
elif [[ -d /opt/ci-venv ]]; then
  # shellcheck source=/dev/null
  source /opt/ci-venv/bin/activate || true
fi

# Convert comma-separated list into normalized module list (space-separated)
_mods_raw="${IMPORTS//,/ }"
_mods_raw="$(echo "${_mods_raw}" | sed -E 's/\bimport\b//g' | tr -s ' ' | sed -e 's/^ *//' -e 's/ *$//')"
MOD_LIST_SP="$(echo "${_mods_raw}" | tr ' ' '\n' | awk NF | paste -sd' ' -)"

# Function to map module names to pip packages (best-effort)
map_packages() {
  local mods="$*" pkg m
  for m in ${mods}; do
    case "${m}" in
      yaml) pkg=pyyaml ;;
      jsonschema) pkg=jsonschema ;;
      mypy) pkg=mypy ;;
      requests) pkg=requests ;;
      typing_extensions) pkg=typing-extensions ;;
      ruamel.yaml|ruamel) pkg=ruamel.yaml ;;
      *) pkg="${m}" ;;
    esac
    printf '%s ' "${pkg}"
  done
}

# Determine which modules are missing using Python (supports dotted names)
MISSING_MODS_SP=""
if ! ENSURE_MODS="${MOD_LIST_SP}" python - <<'PY' >/dev/null 2>"/tmp/ensure.err"; then
import importlib, os, sys
mods = [m for m in os.environ.get('ENSURE_MODS', '').split() if m]
missing = []
for m in mods:
    try:
        importlib.import_module(m)
    except Exception:
        missing.append(m)
if missing:
    print(' '.join(missing))
    sys.exit(1)
sys.exit(0)
PY
  MISSING_MODS_SP="$(ENSURE_MODS="${MOD_LIST_SP}" python - <<'PY'
import importlib, os, sys
mods = [m for m in os.environ.get('ENSURE_MODS', '').split() if m]
missing = []
for m in mods:
    try:
        importlib.import_module(m)
    except Exception:
        missing.append(m)
print(' '.join(missing))
PY
)"
fi

# If nothing is missing, run the command
if [[ -z "${MISSING_MODS_SP}" ]]; then
  exec "$@"
fi

# In GitHub CI (not under ACT), enforce pre-baked deps: do not install at runtime
if [[ -n "${GITHUB_ACTIONS:-}" && -z "${ACT:-}" ]]; then
  echo "[ensure] Missing required Python modules (${MISSING_MODS_SP}). In CI, dependencies must be baked into the image; refusing to install." >&2
  echo "[ensure] To fix: update ci-base image requirements or adjust scripts to include needed packages." >&2
  exit 1
fi

# If we have a baked toolchain (marker ruff importable), prefer to avoid runtime installs under ACT
if python - <<'PY' >/dev/null 2>&1; then
import importlib
import sys
try:
    importlib.import_module('ruff')
except Exception:
    sys.exit(1)
else:
    sys.exit(0)
PY
  if [[ -n "${ACT:-}" ]]; then
    echo "[ensure] Marker toolchain detected (ruff); attempting to avoid runtime pip installs under ACT" >&2
  fi
fi

PKGS="$(map_packages ${MISSING_MODS_SP})"

# Under ACT only: try to bootstrap pip if it's missing; avoid networked installs otherwise
if [[ -n "${ACT:-}" ]]; then
  if ! python - <<'PY' >/dev/null 2>&1; then
import importlib
import sys
try:
    importlib.import_module('pip')
except Exception:
    sys.exit(1)
else:
    sys.exit(0)
PY
    # Try to enable pip inside venv if possible (no apt)
    python -m ensurepip --upgrade >/dev/null 2>&1 || true
  fi
fi

if command -v pip >/dev/null 2>&1; then
  if [[ -n "${ACT:-}" ]]; then echo "[ensure] installing: ${PKGS}" >&2; fi
  # Best-effort install; do not fail the ensure step if installation fails under ACT
  python -m pip install --no-input ${PKGS} >/dev/null 2>&1 || true
else
  if [[ -n "${ACT:-}" ]]; then
    echo "[ensure] pip is not available; proceeding without installing (${PKGS}). The command may fail if imports are required." >&2
  fi
fi

exec "$@"
