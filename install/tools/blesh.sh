#!/usr/bin/env bash
# ble.sh — Bash Line Editor: syntax highlighting + autosuggestions for bash
# (the bash counterpart to zsh's syntax-highlighting / autosuggestions plugins).
# Not a single binary, so we install the prebuilt nightly tarball into .tools.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

dest="$TOOLS_DIR/blesh"
if [ -f "$dest/ble.sh" ]; then
  skip "ble.sh"
  exit 0
fi

url="https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz"
tmp="$(mktemp -d "$CACHE/blesh.XXXXXX")"
log "Installing ble.sh"
if curl -fL --retry 3 --connect-timeout 20 -o "$tmp/ble.tar.xz" "$url" &&
  tar -xJf "$tmp/ble.tar.xz" -C "$tmp"; then
  rm -rf "$dest"
  mv "$tmp"/ble-nightly "$dest"
  rm -rf "$tmp" 2>/dev/null || true
  ok "ble.sh -> $dest/ble.sh"
else
  rm -rf "$tmp" 2>/dev/null || true
  warn "ble.sh: install failed"
  exit 1
fi
