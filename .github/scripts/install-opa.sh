#!/usr/bin/env bash
set -euo pipefail

# install-opa.sh: Fetch and install a specific OPA version into /usr/local/bin/opa
# Usage: ./install-opa.sh <version>
# Env (optional):
#   OPA_SHA256  - expected sha256 checksum for the downloaded binary
#   OPA_ARCH    - override architecture (default: auto-detect amd64/arm64)
#   OPA_CACHE   - cache directory for downloaded binaries (default: /root/.cache/opa)

VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  echo "ERROR: OPA version is required, e.g. ./install-opa.sh 1.7.1" >&2
  exit 2
fi

ARCH_INPUT="${OPA_ARCH:-}"
if [[ -z "${ARCH_INPUT}" ]]; then
  case "$(uname -m)" in
    x86_64|amd64) ARCH_INPUT=amd64 ;;
    aarch64|arm64) ARCH_INPUT=arm64 ;;
    *) ARCH_INPUT=amd64 ;;
  esac
fi

CACHE_DIR="${OPA_CACHE:-/root/.cache/opa}"
mkdir -p "${CACHE_DIR}"

DEST=/usr/local/bin/opa
TMP="${CACHE_DIR}/opa_${VERSION}_${ARCH_INPUT}"
URL_PRIMARY="https://openpolicyagent.org/downloads/v${VERSION}/opa_linux_${ARCH_INPUT}_static"
URL_FALLBACK="https://github.com/open-policy-agent/opa/releases/download/v${VERSION}/opa_linux_${ARCH_INPUT}_static"

echo "Installing OPA v${VERSION} (${ARCH_INPUT})…"
if [[ ! -s "${TMP}" ]]; then
  if ! curl -fSL --retry 10 --retry-delay 5 --retry-connrefused -C - -o "${TMP}" "${URL_PRIMARY}"; then
    curl -fSL --retry 10 --retry-delay 5 --retry-connrefused -C - -o "${TMP}" "${URL_FALLBACK}"
  fi
fi

if [[ -n "${OPA_SHA256:-}" ]]; then
  echo "${OPA_SHA256}  ${TMP}" | sha256sum -c -
else
  echo "WARNING: OPA_SHA256 not provided; skipping checksum verification" >&2
fi

install -m 0755 "${TMP}" "${DEST}"
"${DEST}" version
#!/usr/bin/env bash
set -euo pipefail

# install-opa.sh — deterministic, cached OPA installer
# Env/args:
#   $1 or OPA_VERSION   Version to install (default: 1.8.0)
#   OPA_ARCH            Optional override (amd64|arm64); auto-detected if empty
#   OPA_SHA256          Optional checksum to verify downloaded file
#   DEST                Optional absolute path for install target
# Behavior:
#   - Reuses ~/.cache/opa/opa-<version>-<arch> across runs (fast under ACT mounting ~/.cache)
#   - Tries static build first, then non-static as fallback
#   - Installs to /usr/local/bin when writable/root; else ~/.local/bin; appends directory to GITHUB_PATH

# Load centralized versions if available and OPA_VERSION is not already set
if [[ -z "${OPA_VERSION:-}" ]]; then
  if [[ -f ".github/versions.env" ]]; then
    # shellcheck disable=SC1091
    source ".github/versions.env"
  fi
fi

VERSION="${1:-${OPA_VERSION:-1.8.0}}"
if [[ -z "$VERSION" ]]; then
  echo "OPA version not specified (arg or OPA_VERSION env)" >&2
  exit 2
fi

# Detect arch -> amd64/arm64
if [[ -n "${OPA_ARCH:-}" ]]; then
  ARCH="$OPA_ARCH"
else
  case "$(uname -m || true)" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) ARCH=amd64 ;;
  esac
fi

OPA_SHA256="${OPA_SHA256:-}"

CACHE_DIR="${HOME}/.cache/opa"
mkdir -p "$CACHE_DIR"
CACHE_BIN_STATIC="${CACHE_DIR}/opa-${VERSION}-${ARCH}-static"
CACHE_BIN_REGULAR="${CACHE_DIR}/opa-${VERSION}-${ARCH}"

download_with_retries() {
  local url="$1" dest="$2"
  curl -fSL --retry 10 --retry-delay 5 --retry-connrefused --connect-timeout 15 --max-time 300 -o "$dest" "$url"
}

ensure_cached() {
  local dest="$1" url="$2"
  if [[ ! -f "$dest" ]]; then
    echo "Downloading OPA ${VERSION} (${ARCH})" >&2
    download_with_retries "$url" "$dest"
    chmod +x "$dest" || true
    if ! file "$dest" | grep -qi "ELF"; then
      echo "Downloaded OPA does not look like a binary (url=$url)" >&2
      rm -f "$dest" || true
      return 1
    fi
  fi
}

# Prefer static build
PRIMARY_URL="https://openpolicyagent.org/downloads/v${VERSION}/opa_linux_${ARCH}_static"
FALLBACK_URL="https://openpolicyagent.org/downloads/v${VERSION}/opa_linux_${ARCH}"

if ! ensure_cached "$CACHE_BIN_STATIC" "$PRIMARY_URL"; then
  ensure_cached "$CACHE_BIN_REGULAR" "$FALLBACK_URL"
  CACHE_BIN="$CACHE_BIN_REGULAR"
else
  CACHE_BIN="$CACHE_BIN_STATIC"
fi

if [[ -n "$OPA_SHA256" ]]; then
  echo "${OPA_SHA256}  ${CACHE_BIN}" | sha256sum -c -
fi

# Destination selection
SYS_DIR="/usr/local/bin"
USER_DIR="${HOME}/.local/bin"
TARGET_NAME="opa"

DEST_BIN="${DEST:-}"
if [[ -z "$DEST_BIN" ]]; then
  if [[ "$(id -u)" -eq 0 || -w "$SYS_DIR" ]]; then
    mkdir -p "$SYS_DIR"
    DEST_BIN="${SYS_DIR}/${TARGET_NAME}"
  else
    mkdir -p "$USER_DIR"
    DEST_BIN="${USER_DIR}/${TARGET_NAME}"
  fi
fi

cp "$CACHE_BIN" "$DEST_BIN"
chmod +x "$DEST_BIN" || true

# Export path for downstream steps
if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$(dirname "$DEST_BIN")" >> "$GITHUB_PATH"
fi

echo "Installed OPA to: $DEST_BIN"
"$DEST_BIN" version
