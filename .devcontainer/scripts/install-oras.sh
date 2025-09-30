#!/usr/bin/env bash
set -euo pipefail

# Install ORAS CLI if not present
if command -v oras >/dev/null 2>&1; then
  echo "oras already installed: $(oras version 2>/dev/null | head -n1 || echo present)"
  exit 0
fi

VER=${ORAS_VERSION:-1.2.0}
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH_DL=amd64 ;;
  aarch64|arm64) ARCH_DL=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

OS=linux
TAR="oras_${VER}_${OS}_${ARCH_DL}.tar.gz"
URL="https://github.com/oras-project/oras/releases/download/v${VER}/${TAR}"
echo "Installing ORAS v${VER} from ${URL}"
curl -sSL -o /tmp/oras.tgz "$URL"
mkdir -p /tmp/oras
tar -xzf /tmp/oras.tgz -C /tmp/oras oras
sudo mv /tmp/oras/oras /usr/local/bin/oras
sudo chmod +x /usr/local/bin/oras
oras version || true
