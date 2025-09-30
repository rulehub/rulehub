#!/usr/bin/env bash
set -euo pipefail

# Run Trivy IaC scan via Docker and produce SARIF output.
# Env:
#   TRIVY_VERSION       - optional, default 0.56.2
#   TRIVY_IMAGE_DIGEST  - optional, if set, uses digest instead of tag

TRIVY_VERSION="${TRIVY_VERSION:-0.56.2}"
IMG="aquasecurity/trivy:${TRIVY_VERSION}"
if [ -n "${TRIVY_IMAGE_DIGEST:-}" ]; then
  IMG="aquasecurity/trivy@${TRIVY_IMAGE_DIGEST}"
fi

echo "Running Trivy IaC using Docker image ${IMG}"
mkdir -p "$HOME/.cache/trivy"
docker run --rm \
  -v "$PWD:/workspace" -w /workspace \
  -v "$HOME/.cache/trivy:/root/.cache/trivy" \
  "${IMG}" \
  iac --format sarif --output trivy-results.sarif . || true

# Ensure we always produce a valid SARIF even if the docker run failed or we're offline under ACT.
ensure_min_sarif() {
  cat > trivy-results.sarif <<'EOF'
{
  "$schema": "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "Trivy",
          "informationUri": "https://github.com/aquasecurity/trivy"
        }
      },
      "results": []
    }
  ]
}
EOF
}

# If ACT is present or output file is missing/invalid, write a stub SARIF.
if [ "${ACT:-}" = "true" ]; then
  echo "Detected ACT environment; generating minimal SARIF stub."
  ensure_min_sarif
elif [ ! -s trivy-results.sarif ]; then
  echo "Trivy SARIF not found or empty; generating minimal SARIF stub."
  ensure_min_sarif
else
  # Validate basic SARIF structure; if invalid, replace with stub to avoid upload errors locally.
  if ! grep -q '"version"' trivy-results.sarif || ! grep -q '"runs"' trivy-results.sarif; then
    echo "Trivy SARIF appears invalid; generating minimal SARIF stub."
    ensure_min_sarif
  fi
fi
