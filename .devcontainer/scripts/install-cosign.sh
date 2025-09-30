#!/usr/bin/env bash
set -euo pipefail

if command -v cosign >/dev/null 2>&1; then
  echo "cosign already installed: $(cosign version | sed -n 's/^Version: //p' | head -n1)"
  exit 0
fi

VER=${COSIGN_VERSION:-2.2.4}
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH_DL=amd64 ;;
  aarch64|arm64) ARCH_DL=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

OS=linux
URL="https://github.com/sigstore/cosign/releases/download/v${VER}/cosign-${OS}-${ARCH_DL}"
echo "Installing Cosign v${VER} from ${URL}"
curl -sSL -o /tmp/cosign "$URL"
chmod +x /tmp/cosign
sudo mv /tmp/cosign /usr/local/bin/cosign
cosign version || true
