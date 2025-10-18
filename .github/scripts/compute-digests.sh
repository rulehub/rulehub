#!/usr/bin/env bash
set -euo pipefail

bundle=dist/opa-bundle.tar.gz
manifest=dist/opa-bundle.manifest.json
subjects_b64=1

while [ $# -gt 0 ]; do
  case "$1" in
    --no-subjects-b64) subjects_b64=0; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ ! -s "$bundle" ]; then echo "Missing bundle $bundle" >&2; exit 1; fi
if [ ! -s "$manifest" ]; then echo "Missing manifest $manifest" >&2; exit 1; fi

b_sha=$(sha256sum "$bundle" | cut -d' ' -f1)
m_sha=$(sha256sum "$manifest" | cut -d' ' -f1)
subjects_json="[{\"name\":\"rulehub/opa-bundle.tar.gz\",\"digest\":{\"sha256\":\"$b_sha\"}}]"
if [ $subjects_b64 -eq 1 ]; then
  if base64 --help 2>&1 | grep -q '\-w'; then
    subjects=$(echo -n "$subjects_json" | base64 -w0)
  else
    subjects=$(echo -n "$subjects_json" | base64)
  fi
else
  subjects="$subjects_json"
fi

aggregate_hash=$(jq -r '.aggregate_hash // empty' "$manifest" 2>/dev/null || true)
printf "Bundle SHA256: %s\nManifest SHA256: %s\nAggregate Hash: %s\n" "$b_sha" "$m_sha" "$aggregate_hash" | tee dist/digest-summary.txt

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "bundle_sha256=$b_sha" >> "$GITHUB_OUTPUT"
  echo "manifest_sha256=$m_sha" >> "$GITHUB_OUTPUT"
  echo "aggregate_hash=$aggregate_hash" >> "$GITHUB_OUTPUT"
  echo "subjects_b64=$subjects" >> "$GITHUB_OUTPUT"
fi
