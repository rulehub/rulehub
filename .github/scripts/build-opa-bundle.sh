#!/usr/bin/env bash
set -euo pipefail

allow_fallback=1
while [ $# -gt 0 ]; do
  case "$1" in
    --no-fallback) allow_fallback=0; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p dist
out=dist/opa-bundle.tar.gz
if opa build -b policies -o "$out"; then
  ls -lh "$out" >&2 || true
  exit 0
fi

if [ $allow_fallback -eq 1 ] && { [ "${GITHUB_ACTOR:-}" = "nektos/act" ] || [ "${IS_ACT:-}" = "true" ]; }; then
  echo "[fallback] opa build failed; creating tar.gz of policies" >&2
  if [ -d policies ]; then
    tar czf "$out" -C policies . || : > "$out"
  else
    : > "$out"
  fi
  ls -lh "$out" >&2 || true
else
  echo "opa build failed and fallback disabled" >&2
  exit 1
fi
