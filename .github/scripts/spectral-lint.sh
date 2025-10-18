#!/usr/bin/env bash
# Run Spectral lint with a pinned CLI version and convert JSON to SARIF.
# Defaults:
#  - ruleset: .spectral.yml
#  - output: spectral.sarif
# Usage:
#   spectral-lint.sh [--ruleset PATH] [--out FILE] [--cwd DIR]
set -euo pipefail

RULESET=".spectral.yml"
OUT="spectral.sarif"
CWD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ruleset)
      RULESET="$2"; shift 2;;
    --out|--output)
      OUT="$2"; shift 2;;
    --cwd)
      CWD="$2"; shift 2;;
    *)
      echo "Unknown argument: $1" >&2; exit 2;;
  esac
done

PINNED_SPECTRAL_VERSION="6.11.1"

# Change working dir if provided
if [[ -n "$CWD" ]]; then
  cd "$CWD"
fi

# Prefer globally installed spectral if available in PATH; otherwise use npx with a pinned version.
run_spectral_json() {
  if command -v spectral >/dev/null 2>&1; then
    spectral lint --ruleset "$RULESET" --format json .
  else
    # Use spectral-cli (preferred) pinned version
    npx --yes @stoplight/spectral-cli@"${PINNED_SPECTRAL_VERSION}" lint --ruleset "$RULESET" --format json .
  fi
}

TMP_JSON="$(mktemp -t spectral-XXXXXX.json)"
trap 'rm -f "$TMP_JSON"' EXIT

# Run spectral and capture JSON (exit code reflects lint result; conversion should still run)
set +e
run_spectral_json >"$TMP_JSON"
SPECTRAL_RC=$?
set -e

# Convert JSON -> SARIF using repo tool (assumed present in tree)
python3 tools/convert_spectral_to_sarif.py "$TMP_JSON" --output "$OUT" || true
echo "Wrote $OUT (spectral exit=$SPECTRAL_RC)"

exit $SPECTRAL_RC
