#!/usr/bin/env bash
set -euo pipefail

# Install OPA in devcontainer if not present
if command -v opa >/dev/null 2>&1; then
  echo "opa already installed: $(opa version | sed -n 's/^Version: //p' | head -n1)"
  exit 0
fi

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH_DL=amd64 ;;
  aarch64|arm64) ARCH_DL=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
 esac

curl -sSL -o /tmp/opa "https://openpolicyagent.org/downloads/latest/opa_linux_${ARCH_DL}_static"
chmod +x /tmp/opa
sudo mv /tmp/opa /usr/local/bin/opa
opa version
