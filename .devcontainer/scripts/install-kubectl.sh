#!/usr/bin/env bash
set -euo pipefail

# Install kubectl in devcontainer if not present
if command -v kubectl >/dev/null 2>&1; then
  EXIST_VER=$(kubectl version --client --output=yaml 2>/dev/null | sed -n 's/^gitVersion: //p' | head -n1)
  if [ -z "$EXIST_VER" ]; then
    EXIST_VER=$(kubectl version --client 2>/dev/null | sed -n 's/^Client Version: //p' | head -n1)
  fi
  echo "kubectl already installed: ${EXIST_VER}"
  exit 0
fi

ARCH=$(uname -m)
KVER=$(curl -sSL https://dl.k8s.io/release/stable.txt)
case "$ARCH" in
  x86_64|amd64) ARCH_DL=amd64 ;;
  aarch64|arm64) ARCH_DL=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
 esac

curl -sSL -o /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH_DL}/kubectl"
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/kubectl

KCLI_VER=$(kubectl version --client --output=yaml 2>/dev/null | sed -n 's/^gitVersion: //p' | head -n1)
if [ -z "$KCLI_VER" ]; then
  KCLI_VER=$(kubectl version --client 2>/dev/null | sed -n 's/^Client Version: //p' | head -n1)
fi
echo "Installed kubectl ${KCLI_VER}"
