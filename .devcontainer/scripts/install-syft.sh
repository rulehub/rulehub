#!/usr/bin/env bash
set -euo pipefail

# Desired version (can override with SYFT_VERSION env)
VER=${SYFT_VERSION:-1.31.0}

# If syft exists, check its version; upgrade only if different
if command -v syft >/dev/null 2>&1; then
  CURRENT_VER=$(syft version 2>/dev/null | sed -n 's/^Version:[[:space:]]*//p' | head -n1 || true)
  if [ -n "$CURRENT_VER" ] && [ "$CURRENT_VER" = "$VER" ]; then
    echo "syft already at version $CURRENT_VER"
    exit 0
  else
    echo "syft present (version ${CURRENT_VER:-unknown}); upgrading to ${VER}"
  fi
fi
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH_DL=amd64 ;;
  aarch64|arm64) ARCH_DL=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

OS=linux
TAR="syft_${VER}_${OS}_${ARCH_DL}.tar.gz"
URL="https://github.com/anchore/syft/releases/download/v${VER}/${TAR}"
TMP_TGZ=/tmp/syft.tgz

echo "Installing Syft v${VER} from ${URL}"

set +e
HTTP_STATUS=$(curl -sSL -w '%{http_code}' -o "$TMP_TGZ" "$URL")
CURL_RC=$?
set -e

if [ $CURL_RC -ne 0 ] || [ "$HTTP_STATUS" != "200" ]; then
  echo "[syft] Direct download failed (rc=$CURL_RC status=$HTTP_STATUS). Falling back to install script." >&2
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin "v${VER}" || {
    echo "[syft] Fallback installer failed" >&2
    exit 1
  }
  syft version || true
  exit 0
fi

# Validate gzip (magic header) to catch GH HTML error pages etc
if ! gzip -t "$TMP_TGZ" 2>/dev/null; then
  echo "[syft] Downloaded file is not a valid gzip archive. Falling back to installer script." >&2
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin "v${VER}" || {
    echo "[syft] Fallback installer failed" >&2
    exit 1
  }
  syft version || true
  exit 0
fi

mkdir -p /tmp/syft
if ! tar -xzf "$TMP_TGZ" -C /tmp/syft syft 2>/dev/null; then
  echo "[syft] Tar extraction failed; attempting fallback installer." >&2
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin "v${VER}" || {
    echo "[syft] Fallback installer failed" >&2
    exit 1
  }
else
  sudo mv /tmp/syft/syft /usr/local/bin/syft
  sudo chmod +x /usr/local/bin/syft
fi

syft version || true
