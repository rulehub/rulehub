#!/usr/bin/env bash
set -euo pipefail

# Run a command inside the project's .venv
# Usage: venv-run.sh <command> [args...]

if [ ! -d .venv ]; then
  echo "Error: .venv not found. Run python-venv-install first." >&2
  exit 1
fi

# shellcheck disable=SC1091
. .venv/bin/activate

exec "$@"
