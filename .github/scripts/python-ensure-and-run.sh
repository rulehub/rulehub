#!/usr/bin/env bash
# Ensure minimal Python dependencies are present, then run the given command.
# Usage: python-ensure-and-run.sh "import pkga pkgb ..." <cmd...>
# Example: python-ensure-and-run.sh "import yaml, jsonschema" python tools/validate_metadata.py
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 \"import <modules comma/space separated>\" <command...>" >&2
  exit 2
fi

IMPORTS="$1"; shift

# If a venv exists, activate it to avoid polluting system
if [[ -d .venv ]]; then
  # shellcheck source=/dev/null
  source .venv/bin/activate || true
fi

# Convert comma-separated list into normalized module list and a valid Python import statement
_mods_raw="${IMPORTS//,/ }"
# Strip the keyword 'import' if present, collapse whitespace, trim
_mods_raw="$(echo "${_mods_raw}" | sed -E 's/\bimport\b//g' | tr -s ' ' | sed -e 's/^ *//' -e 's/ *$//')"
# Build comma-separated list
MOD_LIST="$(echo "${_mods_raw}" | tr ' ' '\n' | awk NF | paste -sd, -)"
# Final Python code snippet to try importing
PY_CODE="import ${MOD_LIST}"

# Function to map module names to pip packages
map_packages() {
  local mods pkg
  mods=$(echo "${MOD_LIST}" | tr ',' ' ' | tr ' ' '\n' | awk NF)
  for m in ${mods}; do
    case "${m}" in
      yaml) pkg=pyyaml ;;
      jsonschema) pkg=jsonschema ;;
      mypy) pkg=mypy ;;
      requests) pkg=requests ;;
      typing_extensions) pkg=typing-extensions ;;
      *) pkg="${m}" ;;
    esac
    echo -n "${pkg} "
  done
}

# Try imports; if fail, install mapped packages
if ! python - <<PY >/dev/null 2>&1
try:
  ${PY_CODE}
except Exception:
  raise SystemExit(1)
else:
  raise SystemExit(0)
PY
then
  # shellcheck disable=SC2046
  PKGS="$(map_packages)"
  if [[ -n "${ACT:-}" ]]; then echo "[ensure] installing: ${PKGS}" >&2; fi
  if [[ -n "${PKGS}" ]]; then
    python -m pip install --no-input --no-cache-dir ${PKGS}
  fi
fi

exec "$@"
