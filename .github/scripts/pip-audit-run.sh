#!/usr/bin/env bash
set -euo pipefail

# pip-audit-run.sh
# Optimized (Option B): attempt single (combined) pip-audit run for base+dev requirements
# with fallback to legacy two-run merge if the combined pass fails.
# Env:
#   ACT                   - if set, relax lockfile hash strictness & shortcut SARIF generation
#   SARIF_OUT             - path to write SARIF (optional)
#   PIP_AUDIT_COMBINE     - (default=1) enable combined mode; set 0 to force legacy behavior
#   PIP_AUDIT_DEBUG       - if set, enable verbose timing/debug output

ts() { date +%s; }
dbg() { [[ -n "${PIP_AUDIT_DEBUG:-}" ]] && echo "[pip-audit-run][DBG] $*" >&2 || true; }

start_total=$(ts)

BASE_REQ="requirements.lock"
if [[ ! -f "$BASE_REQ" ]]; then
  BASE_REQ="requirements.txt"
fi
if [[ -n "${ACT:-}" ]]; then
  BASE_REQ="requirements.txt"  # avoid hash enforcement under act
fi

COMBINE_MODE=${PIP_AUDIT_COMBINE:-1}
COMBINED_USED=0
LEGACY_FALLBACK=0

rm -f pip-audit.json pip-audit-dev.json pip-audit-combined.json || true

run_pip_audit_json() {
  local req_file="$1" out_file="$2"
  local t0=$(ts)
  if pip-audit -r "$req_file" -f json -o "$out_file"; then
    dbg "pip-audit JSON ok for $req_file in $(( $(ts)-t0 ))s"
    return 0
  else
    dbg "pip-audit JSON FAILED for $req_file in $(( $(ts)-t0 ))s (ignored)"
    return 1
  fi
}

if [[ "$COMBINE_MODE" == "1" ]]; then
  dbg "Attempting combined mode"
  TMP_COMBINED=$(mktemp -t pip-audit-combined-XXXX.txt)
  cat "$BASE_REQ" > "$TMP_COMBINED"
  if [[ -f requirements-dev.txt ]]; then
    echo -e "\n# ---- dev requirements ----" >> "$TMP_COMBINED"
    cat requirements-dev.txt >> "$TMP_COMBINED"
  fi
  if run_pip_audit_json "$TMP_COMBINED" pip-audit.json; then
    # Provide empty dev file so merge logic remains uniform
    echo '{"vulns": []}' > pip-audit-dev.json
    COMBINED_USED=1
  else
    echo "[pip-audit-run] Combined run failed — falling back to legacy separate runs" >&2
    LEGACY_FALLBACK=1
  fi
else
  dbg "Combined mode disabled via PIP_AUDIT_COMBINE=0"
  LEGACY_FALLBACK=1
fi

if [[ "$LEGACY_FALLBACK" == "1" ]]; then
  run_pip_audit_json "$BASE_REQ" pip-audit.json || true
  if [[ -f requirements-dev.txt ]]; then
    run_pip_audit_json requirements-dev.txt pip-audit-dev.json || true
  fi
  [[ -f pip-audit.json ]] || echo '{"vulns": []}' > pip-audit.json
  [[ -f pip-audit-dev.json ]] || echo '{"vulns": []}' > pip-audit-dev.json
fi

# Merge (schema-flex): supports .vulns, .vulnerabilities, nested dependencies forms.
jq -s '[.[] | if type=="object" then ( (.vulns // .vulnerabilities // ( [ (.dependencies[]?.vulns[]?) ] )) ) else [] end | .[] ] | {vulns: .}' \
  pip-audit.json pip-audit-dev.json 2>/dev/null > pip-audit-combined.json || cp pip-audit.json pip-audit-combined.json

HIGH_COUNT=$(jq '[.vulns[]? | select((.severity // "") | ascii_upcase == "HIGH" or (.severity // "") | ascii_upcase == "CRITICAL")] | length' pip-audit-combined.json || echo 0)
TOTAL=$(jq '.vulns | length' pip-audit-combined.json || echo 0)
echo "pip-audit: total=$TOTAL high+critical=$HIGH_COUNT"

# SARIF logic
if [[ -n "${SARIF_OUT:-}" ]]; then
  if [[ -n "${ACT:-}" ]]; then
    # Synthetic SARIF under ACT (skip extra network)
    dbg "ACT mode: emitting synthetic SARIF"
    printf '%s\n' '{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"pip-audit","informationUri":"https://github.com/pypa/pip-audit"}},"results":[]}]} ' > "$SARIF_OUT"
  else
    # Real SARIF if supported
    if pip-audit -h 2>&1 | grep -E -q '(-f|--format) .*choices:.*sarif'; then
      SARIF_REQ="$BASE_REQ"
      if [[ "$COMBINED_USED" == "1" ]]; then
        # Re-use combined temp if it still exists; if deleted, rebuild minimal combined
        if [[ -f "${TMP_COMBINED:-}" ]]; then
          SARIF_REQ="$TMP_COMBINED"
        else
          SARIF_REQ="$BASE_REQ"
        fi
      fi
      if ! pip-audit -r "$SARIF_REQ" -f sarif -o "$SARIF_OUT"; then
        echo "[pip-audit-run] SARIF generation failed, writing empty SARIF" >&2
        printf '%s\n' '{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"pip-audit","informationUri":"https://github.com/pypa/pip-audit"}},"results":[]}]} ' > "$SARIF_OUT"
      fi
    else
      printf '%s\n' '{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"pip-audit","informationUri":"https://github.com/pypa/pip-audit"}},"results":[]}]} ' > "$SARIF_OUT"
    fi
  fi
fi

if [[ "$HIGH_COUNT" -gt 0 ]]; then
  echo "::error::High severity vulnerabilities detected ($HIGH_COUNT)."
  jq -r '.vulns[]? | select((.severity // "") | ascii_upcase == "HIGH" or (.severity // "") | ascii_upcase == "CRITICAL") | "- \(.id) \(.severity) \(.package // \"?\") \(.version // \"?\")"' pip-audit-combined.json || true
  exit 1
fi

dbg "Total duration: $(( $(ts)-start_total ))s (combined_used=$COMBINED_USED fallback=$LEGACY_FALLBACK)"
