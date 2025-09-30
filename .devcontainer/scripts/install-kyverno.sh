#!/usr/bin/env bash
set -euo pipefail

# Install Kyverno CLI in devcontainer if not present
if command -v kyverno >/dev/null 2>&1; then
  echo "kyverno already installed: $(kyverno version 2>/dev/null | head -n1 || echo present)"
  exit 0
fi

VER=${KYVERNO_VERSION:-v1.15.1}
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH_DL=x86_64 ;;
  aarch64|arm64) ARCH_DL=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
 esac

URL="https://github.com/kyverno/kyverno/releases/download/${VER}/kyverno-cli_${VER}_linux_${ARCH_DL}.tar.gz"
echo "Installing Kyverno CLI ${VER} from ${URL}"
curl -sSL -o /tmp/kyverno.tgz "$URL"
mkdir -p /tmp/kyverno-cli
tar -xzf /tmp/kyverno.tgz -C /tmp/kyverno-cli
sudo mv /tmp/kyverno-cli/kyverno /usr/local/bin/kyverno
sudo chmod +x /usr/local/bin/kyverno
kyverno version || true
