#!/usr/bin/env bash
# Install bundled Fira Mono Nerd Font (for starship/zellij/tmux glyphs).
set -euo pipefail
source "$(dirname "$0")/../common.sh"

dest="$FONT_DIR/$DOTFILES_FONT_FILE"

if [ ! -f "$DOTFILES_FONT_SRC" ]; then
  warn "bundled font not found: $DOTFILES_FONT_SRC"
  exit 1
fi

if [ -f "$dest" ]; then
  skip "$DOTFILES_FONT_LABEL"
else
  log "Installing $DOTFILES_FONT_LABEL -> $FONT_DIR"
  mkdir -p "$FONT_DIR"
  install -m 0644 "$DOTFILES_FONT_SRC" "$dest"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  ok "$DOTFILES_FONT_LABEL (set terminal font to \"$DOTFILES_FONT_LABEL\")"
fi
