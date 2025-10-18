#!/usr/bin/env bash
set -euo pipefail

# opa-check.sh: Run opa check policies with ACT-aware behavior.
# If OPA_VERSION is set and opa-select exists, use the selected version.

OPA_BIN=${OPA_BIN:-}
if [[ -z "$OPA_BIN" ]]; then
  OPA_BIN="opa"
  if command -v opa-select >/dev/null 2>&1 && [[ -n "${OPA_VERSION:-}" ]]; then
    SEL_BIN=$(opa-select "${OPA_VERSION}" --print-bin || true)
    if [[ -n "$SEL_BIN" && -x "$SEL_BIN" ]]; then
      OPA_BIN="$SEL_BIN"
    fi
  fi
fi

if [[ "${ACT:-}" == "true" ]]; then
  echo "ACT=true detected; allowing opa check to continue on error"
  set +e
  "$OPA_BIN" check policies || true
else
  "$OPA_BIN" check policies
fi
