#!/usr/bin/env bash
set -euo pipefail

# Install Helm in devcontainer if not present
if command -v helm >/dev/null 2>&1; then
  if helm version --short >/dev/null 2>&1; then
    echo "helm already installed: $(helm version --short)"
  else
    echo "helm already installed: $(helm version 2>/dev/null | head -n1)"
  fi
  exit 0
fi

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH_DL=amd64 ;;
  aarch64|arm64) ARCH_DL=arm64 ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
 esac

curl -sSL https://get.helm.sh/helm-v3.15.3-linux-${ARCH_DL}.tar.gz -o /tmp/helm.tgz
mkdir -p /tmp/helm
tar -xzf /tmp/helm.tgz -C /tmp/helm
sudo mv /tmp/helm/linux-${ARCH_DL}/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm

if helm version --short >/dev/null 2>&1; then
  helm version --short
else
  helm version 2>/dev/null | head -n1
fi
