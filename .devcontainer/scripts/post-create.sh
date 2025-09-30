#!/usr/bin/env bash
set -euo pipefail

echo "[devcontainer] Post-create start"

# Base OS packages (quietly) - skip if already installed marker exists
if [ ! -f /usr/local/bin/.rulehub_base_pkgs ]; then
  echo "[devcontainer] Installing base packages (jq, yq, unzip, zip, git, curl)"
  sudo apt-get update -y >/dev/null 2>&1 || true
  sudo apt-get install -y --no-install-recommends jq unzip zip git curl ca-certificates >/dev/null 2>&1 || true
  # yq (v4) via binary
  if ! command -v yq >/dev/null 2>&1; then
    ARCH=$(uname -m); case "$ARCH" in x86_64|amd64) ARCH_DL=amd64 ;; aarch64|arm64) ARCH_DL=arm64 ;; *) ARCH_DL=amd64 ;; esac
    sudo curl -sSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_${ARCH_DL}" && sudo chmod +x /usr/local/bin/yq || true
  fi
  sudo touch /usr/local/bin/.rulehub_base_pkgs || true
fi

# Install CLIs first
bash .devcontainer/scripts/install-kubectl.sh
bash .devcontainer/scripts/install-helm.sh
bash .devcontainer/scripts/install-kyverno.sh
bash .devcontainer/scripts/install-opa.sh
bash .devcontainer/scripts/install-oras.sh
bash .devcontainer/scripts/install-cosign.sh
bash .devcontainer/scripts/install-syft.sh

#############################################
# Python virtual environment (resilient)
#############################################
ensure_venv() {
  # Skip if already healthy
  if [ -x .venv/bin/python ]; then
    return 0
  fi
  echo "[devcontainer] (re)creating virtualenv (.venv)"

  # Helper: try_via_venv MODULE
  try_std_venv() {
    echo "[devcontainer] Attempt: python3 -m venv .venv"
    python3 -m venv .venv 2>/dev/null
  }

  # 1. Standard venv
  if ! try_std_venv; then
    echo "[devcontainer] Standard venv failed. Attempting to install python3-venv (may only help system python)." >&2
    sudo apt-get update -y >/dev/null 2>&1 || true
    sudo apt-get install -y --no-install-recommends python3-venv >/dev/null 2>&1 || true
    try_std_venv || true
  fi

  # 2. ensurepip + retry (covers cases missing pip inside interpreter)
  if [ ! -d .venv ] || [ ! -x .venv/bin/python ]; then
    echo "[devcontainer] Trying ensurepip then recreating venv" >&2
    python3 -m ensurepip --upgrade >/dev/null 2>&1 || true
    rm -rf .venv
    try_std_venv || true
  fi

  # 3. virtualenv fallback
  if [ ! -d .venv ] || [ ! -x .venv/bin/python ]; then
    echo "[devcontainer] Falling back to virtualenv package" >&2
    python3 -m pip install --upgrade --quiet pip setuptools wheel || true
    python3 -m pip install --quiet virtualenv || true
    python3 -m virtualenv .venv || true
  fi

  # 4. Last resort: try 'python' if python3 path mismatch
  if [ ! -d .venv ] || [ ! -x .venv/bin/python ]; then
    if command -v python >/dev/null 2>&1; then
      echo "[devcontainer] Retrying with 'python' interpreter" >&2
      rm -rf .venv
      python -m venv .venv 2>/dev/null || python -m virtualenv .venv || true
    fi
  fi

  # Provide python3 symlink if missing but python exists
  if [ -x .venv/bin/python ] && [ ! -x .venv/bin/python3 ]; then
    ( cd .venv/bin && ln -s python python3 2>/dev/null || true )
  fi

  # Basic health check
  if [ ! -x .venv/bin/python ]; then
    echo "[devcontainer] ERROR: .venv/bin/python still missing after all attempts" >&2
    return 1
  fi

  # Upgrade core tooling quietly
  . .venv/bin/activate
  python -m pip install --upgrade --quiet pip setuptools wheel || true
}

if ! ensure_venv; then
  echo "[devcontainer] WARNING: Virtualenv creation failed; skipping dependency installation." >&2
else
  VENV_HEALTHY=1
fi

# Install dev + tools deps using Makefile (handles lockfiles)
if command -v make >/dev/null 2>&1 && [ "${VENV_HEALTHY:-0}" = "1" ]; then
  # Allow opt-out for faster container startup
  if [ "${RULEHUB_SKIP_DEPS:-0}" = "1" ]; then
    echo "[devcontainer] RULEHUB_SKIP_DEPS=1 -> skipping dependency installation"
  else
    echo "[devcontainer] Installing dev dependencies via make setup-dev"
    make setup-dev || true
    # Avoid duplicate work if deps overlap (setup-dev already installs runtime requirements-dev.lock which supersets runtime)
    if [ "${RULEHUB_SKIP_RUNTIME_DEPS:-0}" != "1" ]; then
      echo "[devcontainer] Installing runtime dependencies via make deps"
      make deps || true
    else
      echo "[devcontainer] RULEHUB_SKIP_RUNTIME_DEPS=1 -> skipping make deps"
    fi
  fi
fi

#############################################
# Pre-commit hooks
#############################################
if [ -f .pre-commit-config.yaml ]; then
  if [ "${VENV_HEALTHY:-0}" = "1" ]; then
    if ! .venv/bin/pre-commit --version >/dev/null 2>&1; then
      echo "[devcontainer] Installing pre-commit package"
      . .venv/bin/activate
      pip install --quiet pre-commit || true
    fi
    echo "[devcontainer] Installing pre-commit hooks"
    .venv/bin/pre-commit install --install-hooks -t pre-commit -t commit-msg || true
  else
    echo "[devcontainer] Skipping pre-commit (venv unhealthy)" >&2
  fi
fi


# Print summary
echo "Tool versions:"
# kubectl (fallback if --short unsupported)
if command -v kubectl >/dev/null 2>&1; then
  if kubectl version --client --short >/dev/null 2>&1; then
    kubectl version --client --short || true
  else
    kubectl version --client 2>/dev/null | head -n3 || true
  fi
fi
# helm (fallback)
if command -v helm >/dev/null 2>&1; then
  if helm version --short >/dev/null 2>&1; then
    helm version --short || true
  else
    helm version 2>/dev/null | head -n1 || true
  fi
fi
kyverno version 2>/dev/null | head -n1 || true
opa version | head -n1 || true
oras version 2>/dev/null | head -n1 || true
cosign version | sed -n 's/^Version: //p' | head -n1 || true
syft version 2>/dev/null | head -n1 || true
python --version || true
[ -x .venv/bin/python ] && .venv/bin/python --version || true

echo "[devcontainer] Post-create done"
