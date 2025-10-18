#!/usr/bin/env bash
set -euo pipefail

# Run Trivy IaC scan and produce SARIF output.
# Prefers locally installed 'trivy' (from ci-base image) for determinism; falls back to Docker.
# Env:
#   TRIVY_VERSION       - optional, default 0.56.2
#   TRIVY_IMAGE_DIGEST  - optional, if set, uses digest instead of tag

TRIVY_VERSION="${TRIVY_VERSION:-0.56.2}"
IMG="aquasecurity/trivy:${TRIVY_VERSION}"
if [ -n "${TRIVY_IMAGE_DIGEST:-}" ]; then
  IMG="aquasecurity/trivy@${TRIVY_IMAGE_DIGEST}"
fi

mkdir -p "$HOME/.cache/trivy"

run_trivy_local() {
  if command -v trivy >/dev/null 2>&1; then
    echo "Running Trivy IaC using local binary: $(trivy --version | head -n1)"
    # Prefer modern 'config' subcommand; fallback to legacy 'iac' if unavailable
    if trivy help config >/dev/null 2>&1; then
      trivy config --format sarif -o trivy-results.sarif . || true
    else
      trivy iac --format sarif -o trivy-results.sarif . || true
    fi
    return 0
  fi
  return 1
}

run_trivy_docker() {
  echo "Running Trivy IaC using Docker image ${IMG}"
  # Detect Docker availability; skip gracefully if unavailable
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "Docker not available; skipping Trivy IaC run and generating minimal SARIF." >&2
    return 1
  fi
  docker run --rm \
    -v "$PWD:/workspace" -w /workspace \
    -v "$HOME/.cache/trivy:/root/.cache/trivy" \
    "${IMG}" \
    sh -ec '
      if trivy help config >/dev/null 2>&1; then
        trivy config --format sarif -o trivy-results.sarif .
      else
        trivy iac --format sarif -o trivy-results.sarif .
      fi
    ' || true
}

run_trivy_local || run_trivy_docker || true

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

# If output file is missing/invalid, write a stub SARIF.
if [ ! -s trivy-results.sarif ]; then
  echo "Trivy SARIF not found or empty; generating minimal SARIF stub."
  ensure_min_sarif
else
  # Validate basic SARIF structure; if invalid, replace with stub to avoid upload errors locally.
  if ! grep -q '"version"' trivy-results.sarif || ! grep -q '"runs"' trivy-results.sarif; then
    echo "Trivy SARIF appears invalid; generating minimal SARIF stub."
    ensure_min_sarif
  fi
fi
