#!/usr/bin/env bash
set -euo pipefail
repos=(
  "trufflesecurity/trufflehog"
  "docker/login-action"
  "sigstore/cosign-installer"
  "softprops/action-gh-release"
  "google-github-actions/release-please-action"
  "peaceiris/actions-gh-pages"
  "bridgecrewio/checkov-action"
  "ossf/scorecard-action"
)
out=/workspaces/rulehub/actions_latest.out
: > "$out"
for repo in "${repos[@]}"; do
  echo "Checking $repo" >&2
  rel=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | python3 -c "import sys,json; j=json.load(sys.stdin) if sys.stdin.readable() else {}; print(j.get('tag_name',''))") || true
  if [ -n "$rel" ]; then
    echo "$repo|release|$rel" >> "$out"
    continue
  fi
  tag=$(curl -s "https://api.github.com/repos/$repo/tags" | python3 -c "import sys,json; j=json.load(sys.stdin); print(j[0]['name'] if j else '')") || true
  if [ -n "$tag" ]; then
    echo "$repo|tag|$tag" >> "$out"
  else
    echo "$repo|none|(none)" >> "$out"
  fi
done

printf "Wrote results to %s\n" "$out"
