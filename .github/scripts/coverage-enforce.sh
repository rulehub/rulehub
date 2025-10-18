#!/usr/bin/env bash
set -euo pipefail

# coverage-enforce.sh
# Generate coverage artifacts and enforce that committed artifacts are up-to-date.

# Ensure venv preference
if [[ -d .venv ]]; then
  # shellcheck source=/dev/null
  source .venv/bin/activate || true
elif [[ -d /opt/ci-venv ]]; then
  # shellcheck source=/dev/null
  source /opt/ci-venv/bin/activate || true
fi

# Generate coverage artifacts
if [[ "${ACT:-}" = "true" ]]; then
  # Under act/local, ensure modules are present dynamically
  bash .github/scripts/python-ensure-and-run.sh "import yaml, jsonschema" python tools/coverage_map.py
else
  # In CI images, dependencies are preinstalled in /opt/ci-venv
  python tools/coverage_map.py
fi

# Validate plugin index schema if present (use dedicated script)
if [[ -f tools/schemas/plugin-index.schema.json && -f dist/index.json ]]; then
  if [[ "${ACT:-}" = "true" ]]; then
    bash .github/scripts/python-ensure-and-run.sh "import jsonschema" python tools/validate_index_schema.py
  else
    python tools/validate_index_schema.py
  fi
fi

# Enforce committed artifacts up-to-date (skip under ACT)
if [[ "${ACT:-}" = "true" ]]; then
  echo "[act] Skipping artifact enforcement (dist/index.json may be untracked locally)"
  exit 0
fi

# Ensure generated files exist before diffing
missing=()
for f in docs/coverage.md dist/index.json; do
  [[ -f "$f" ]] || missing+=("$f")
done
if (( ${#missing[@]} > 0 )); then
  echo "ERROR: Expected generated artifacts missing: ${missing[*]}"
  echo 'Regenerate via: make coverage (or python3 tools/coverage_map.py) and commit them.'
  exit 1
fi

# If files are untracked, 'git diff' won't show them; detect this case explicitly
UNTRACKED=$(git ls-files --others --exclude-standard -- docs/coverage.md dist/index.json || true)
if [[ -n "$UNTRACKED" ]]; then
  echo "ERROR: Generated artifacts are untracked:"
  echo "$UNTRACKED"
  echo 'Please git add and commit the artifacts after regeneration.'
  exit 1
fi

git status --short || true
CHANGED=$(git diff --name-only -- docs/coverage.md dist/index.json || true)
if [[ -n "$CHANGED" ]]; then
  echo 'ERROR: Generated artifacts are out of date:'
  echo "$CHANGED"
  echo 'Run locally: make coverage (or python3 tools/coverage_map.py) and commit updated docs/coverage.md & dist/index.json.'
  exit 1
fi

echo 'Artifact check passed: docs/coverage.md and dist/index.json are up to date.'

# Optional: write a tiny summary for GitHub UI (skip under ACT)
if [[ -n "${GITHUB_STEP_SUMMARY:-}" && "${ACT:-}" != "true" ]]; then
  {
    echo "### Coverage"
    if [[ -f docs/coverage.md ]]; then
      # Extract first heading line as title snippet
      head -n 5 docs/coverage.md | sed -n '1p' | sed 's/^#\s*//g' || true
    fi
    if [[ -f dist/index.json ]]; then
      echo
      echo "Index present: dist/index.json"
    fi
  } >> "$GITHUB_STEP_SUMMARY"
fi
