#!/usr/bin/env bash
# Install JetBrains Mono Nerd Font (for starship/zellij/tmux glyphs).
set -euo pipefail
source "$(dirname "$0")/../common.sh"

marker="$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf"
if [ -f "$marker" ]; then
  skip "JetBrains Mono Nerd Font"
  exit 0
fi
command -v unzip >/dev/null 2>&1 || { warn "unzip required"; exit 1; }
command -v curl  >/dev/null 2>&1 || { warn "curl required"; exit 1; }

log "Installing JetBrains Mono Nerd Font -> $FONT_DIR"
mkdir -p "$FONT_DIR" "$CACHE"
tmp="$(mktemp -d "$CACHE/jetbrains-mono.XXXXXX")"
if curl -fsSL -o "$tmp/JetBrainsMono.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    && unzip -q "$tmp/JetBrainsMono.zip" -d "$FONT_DIR"; then
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  ok "JetBrains Mono Nerd Font (set it as your terminal font)"
else
  warn "font install failed (cosmetic only)"
fi
rm -rf "$tmp" 2>/dev/null || true
