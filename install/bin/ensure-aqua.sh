#!/usr/bin/env bash
# Bootstrap aqua into $AQUA_ROOT_DIR (rootless, no sudo).
# Usage: ensure-aqua.sh
#   - logs to stderr
#   - prints aqua binary path on stdout (last line only) on success
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../common.sh
source "$DOTFILES/install/common.sh"

# Keep status messages off stdout so callers can capture the path cleanly.
log() { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
ok() { printf '\033[1;32m✔\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }

AQUA_ROOT_DIR="${AQUA_ROOT_DIR:-$DOTFILES/var/tools/aqua}"
AQUA_BIN="$AQUA_ROOT_DIR/bin/aqua"
AQUA_BOOTSTRAP_VERSION="${AQUA_BOOTSTRAP_VERSION:-v2.48.1}"

mkdir -p "$AQUA_ROOT_DIR/bin" "$CACHE"

if [ -x "$AQUA_BIN" ]; then
  printf '%s\n' "$AQUA_BIN"
  exit 0
fi

arch="$(uname -m)"
case "$arch" in
  x86_64 | amd64) goarch=amd64 ;;
  aarch64 | arm64) goarch=arm64 ;;
  *)
    warn "aqua: unsupported arch $arch"
    exit 1
    ;;
esac

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
asset="aqua_${os}_${goarch}.tar.gz"
url="https://github.com/aquaproj/aqua/releases/download/${AQUA_BOOTSTRAP_VERSION}/${asset}"
tmp="$(mktemp -d "$CACHE/aqua-boot.XXXXXX")"

log "Installing aqua ${AQUA_BOOTSTRAP_VERSION} (rootless) -> $AQUA_ROOT_DIR"
(
  cd "$tmp"
  curl -fsSL --retry 3 --connect-timeout 30 -o aqua.tgz "$url"
  # Shared/NFS homes often reject tar ownership restore — strip owners.
  tar --no-same-owner -xzf aqua.tgz
  install -m 0755 aqua "$AQUA_BIN"
) || {
  rm -rf "$tmp"
  warn "aqua: bootstrap failed"
  exit 1
}
rm -rf "$tmp"

[ -x "$AQUA_BIN" ] || {
  warn "aqua: binary missing after install"
  exit 1
}
ok "aqua -> $AQUA_BIN"
printf '%s\n' "$AQUA_BIN"
