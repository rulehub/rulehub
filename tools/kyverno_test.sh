#!/usr/bin/env bash
set -euo pipefail

# Run Kyverno tests locally, preferring the installed CLI. If unavailable,
# try running via the official kyverno-cli container. Fallback with guidance.

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TEST_DIR="$ROOT_DIR/tests/kyverno"

if command -v kyverno >/dev/null 2>&1; then
  exec kyverno test "$TEST_DIR" --v=0
fi

if command -v docker >/dev/null 2>&1; then
  TAG="${KYVERNO_CLI_TAG:-latest}"
  exec docker run --rm \
    -v "$ROOT_DIR":/workspace \
    -w /workspace \
    "ghcr.io/kyverno/kyverno-cli:${TAG}" \
    test tests/kyverno --v=0
fi

echo "Kyverno CLI not found and Docker is not available."
echo "Install kyverno CLI: https://kyverno.io/docs/kyverno-cli/install/"
exit 127
