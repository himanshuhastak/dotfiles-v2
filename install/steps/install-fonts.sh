#!/usr/bin/env bash
# Install all bundled Nerd Fonts from nerdfonts/ (for starship/zellij glyphs).
# Fonts are vendored in-repo — we never re-download them.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

if [ ! -d "$DOTFILES_NERDFONTS_DIR" ]; then
  warn "bundled fonts dir not found: $DOTFILES_NERDFONTS_DIR"
  exit 1
fi

font_files=()
shopt -s nullglob
for ext in otf ttf OTF TTF; do
  font_files+=("$DOTFILES_NERDFONTS_DIR"/*."$ext")
done
shopt -u nullglob

if [ ${#font_files[@]} -eq 0 ]; then
  warn "no font files found in $DOTFILES_NERDFONTS_DIR"
  exit 1
fi

installed=0
mkdir -p "$FONT_DIR"
for src in "${font_files[@]}"; do
  name="$(basename "$src")"
  dest="$FONT_DIR/$name"
  if [ -f "$dest" ]; then
    skip "$name"
  else
    log "Installing $name -> $FONT_DIR"
    install -m 0644 "$src" "$dest"
    ok "$name"
    installed=$((installed + 1))
  fi
done

if [ "$installed" -gt 0 ]; then
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
fi
