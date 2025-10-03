#!/usr/bin/env bash
set -euo pipefail

# install-opa.sh [OPA_VERSION]
# Installs OPA into PATH if not present, using a local cache at ~/.cache/opa.
# Tries static binary first, then regular if static is unavailable.

VERSION="${1:-${OPA_VERSION:-}}"
if [ -z "${VERSION}" ]; then
  echo "Usage: $0 <OPA_VERSION> or set OPA_VERSION env" >&2
  exit 2
fi

mkdir -p "${HOME}/.cache/opa"
CACHE_BIN="${HOME}/.cache/opa/opa-${VERSION}"

# If an opa exists and matches requested version, reuse it
if command -v opa >/dev/null 2>&1; then
  if opa version 2>/dev/null | grep -q "${VERSION}"; then
    echo "OPA ${VERSION} already installed in PATH" >&2
    exit 0
  fi
fi

if [ ! -f "${CACHE_BIN}" ]; then
  echo "Downloading OPA ${VERSION}" >&2
  # Prefer static build when available
  if curl -fsSL -o "${CACHE_BIN}" "https://openpolicyagent.org/downloads/v${VERSION}/opa_linux_amd64_static"; then
    :
  else
    curl -fsSL -o "${CACHE_BIN}" "https://openpolicyagent.org/downloads/v${VERSION}/opa_linux_amd64"
  fi
  # Basic sanity check: file should be executable ELF binary
  chmod +x "${CACHE_BIN}"
  if ! file "${CACHE_BIN}" | grep -qi "ELF"; then
    echo "Downloaded file does not look like a binary; aborting." >&2
    exit 1
  fi
else
  echo "Using cached OPA ${VERSION}" >&2
  chmod +x "${CACHE_BIN}" || true
fi

# Try installing into /usr/local/bin if permitted; otherwise fall back to user bin
DEST="${HOME}/.local/bin/opa"
if command -v sudo >/dev/null 2>&1; then
  sudo mkdir -p /usr/local/bin || true
  if sudo cp "${CACHE_BIN}" /usr/local/bin/opa 2>/dev/null; then
    DEST=/usr/local/bin/opa
  fi
fi

mkdir -p "$(dirname "$DEST")"
cp "${CACHE_BIN}" "$DEST"
chmod +x "$DEST"
echo "$(dirname "$DEST")" >> "$GITHUB_PATH"

opa version
