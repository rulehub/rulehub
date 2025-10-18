#!/usr/bin/env bash
set -euo pipefail

# Act-friendly Renovate dry-run using the official container.
# - Avoids job.container under act
# - Uses working directory mount instead of --local-dir flag (compat across Renovate versions)

LOG_LEVEL="${LOG_LEVEL:-info}"
RENOVATE_DRY_RUN="${RENOVATE_DRY_RUN:-full}"
# Token optional for platform=local; leave empty by default under act
GITHUB_COM_TOKEN="${GITHUB_COM_TOKEN:-}"
# Allow overriding image via env; default to pinned tag used in CI
DOCKER_IMG="${RENOVATE_IMAGE:-ghcr.io/renovatebot/renovate:37}"

mkdir -p dist
cat > dist/renovate.local.json <<'JSON'
{
  "extends": ["config:recommended"],
  "dependencyDashboard": false,
  "prHourlyLimit": 0
}
JSON

# Limit managers under act for speed/stability
MANAGERS="${MANAGERS:-github-actions}"
echo "Using Renovate image: ${DOCKER_IMG}"
echo "Using managers: ${MANAGERS}"

# Optional timeout wrapper if present
TOUT=""
if command -v timeout >/dev/null 2>&1; then
  TOUT="timeout -k 10 300s"
  echo "Using timeout wrapper: ${TOUT}"
fi

# Print Renovate version (best-effort)
docker run --rm -u 0:0 "${DOCKER_IMG}" --version || true

# Use env for config path for wider CLI compatibility (older Renovate may not support --config-file)
export RENOVATE_CONFIG_FILE="/repo/dist/renovate.local.json"

# Resolve real repo dir for bind mount (under act, prefer PWD which maps to host path)
REPO_DIR="${PWD}"
echo "Mounting repo: ${REPO_DIR} -> /repo"

# Print-config (best-effort). Rely on container entrypoint; use -w /repo instead of deprecated flags for broader CLI compatibility.
docker run --rm -u 0:0 \
  -v "${REPO_DIR}":/repo \
  -w /repo \
  -e LOG_LEVEL \
  -e RENOVATE_DRY_RUN \
  -e GITHUB_COM_TOKEN \
  -e RENOVATE_CONFIG_FILE \
  "${DOCKER_IMG}" \
  --platform=local \
  --require-config=true \
  --enabled-managers="${MANAGERS}" \
  --print-config > dist/renovate.print-config.json || true

# Dry-run (best-effort)
${TOUT} docker run --rm -u 0:0 \
  -v "${REPO_DIR}":/repo \
  -w /repo \
  -e LOG_LEVEL \
  -e RENOVATE_DRY_RUN \
  -e GITHUB_COM_TOKEN \
  -e RENOVATE_CONFIG_FILE \
  "${DOCKER_IMG}" \
  --platform=local \
  --require-config=true \
  --enabled-managers="${MANAGERS}" \
  --log-file=/repo/dist/renovate.log || true

echo "Renovate dry-run (act) completed. See dist/renovate.log if present." > dist/renovate-summary.txt
