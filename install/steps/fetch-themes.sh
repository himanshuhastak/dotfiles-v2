#!/usr/bin/env bash
# Fetch Catppuccin Mocha theme assets into home/ (chezmoi source).
# Usage: fetch-themes.sh [--force]
set -euo pipefail
source "$(dirname "$0")/../common.sh"

FORCE=0
[ "${1:-}" = --force ] && FORCE=1
HOME_SRC="$DOTFILES/home"

FLAVOUR=mocha
PALETTE=catppuccin_mocha

fetch_if_missing() {
  local dest="$1" url="$2" label="$3"
  if [ -f "$dest" ] && [ "$FORCE" -eq 0 ]; then
    skip "$label (use --force to refresh)"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  log "Fetching $label"
  curl -fsSL -o "$dest" "$url"
  ok "$label -> $dest"
}

patch_starship_character() {
  local cfg="$1"
  [ -f "$cfg" ] || return 0
  sed -i \
    -e 's/^success_symbol = .*/success_symbol = "[❯](peach)"/' \
    -e 's/^error_symbol = .*/error_symbol = "[❯](red)"/' \
    -e 's/^vimcmd_symbol = .*/vimcmd_symbol = "[❮](subtext1)"/' \
    "$cfg"
}

starship_cfg="$HOME_SRC/dot_config/starship.toml"
if [ -f "$starship_cfg" ] && [ "$FORCE" -eq 0 ]; then
  skip "catppuccin starship.toml (use --force to refresh)"
  patch_starship_character "$starship_cfg"
else
  mkdir -p "$(dirname "$starship_cfg")"
  log "Fetching catppuccin/starship theme"
  curl -fsSL -o "$starship_cfg" \
    https://raw.githubusercontent.com/catppuccin/starship/main/starship.toml
  sed -i "s/palette = \"catppuccin_macchiato\"/palette = \"$PALETTE\"/" "$starship_cfg"
  if ! grep -q '^scan_timeout' "$starship_cfg"; then
    sed -i '/^palette = /i\
# NFS home: git/repo scans can exceed the default 30ms timeout.\
scan_timeout = 10000\
command_timeout = 5000\
' "$starship_cfg"
  fi
  sed -i '1i# Catppuccin for Starship — https://github.com/catppuccin/starship' "$starship_cfg"
  patch_starship_character "$starship_cfg"
  ok "starship.toml ($PALETTE) -> $starship_cfg"
fi

bat_theme="$HOME_SRC/dot_config/bat/themes/Catppuccin Mocha.tmTheme"
fetch_if_missing "$bat_theme" \
  "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme" \
  "bat Catppuccin Mocha.tmTheme"

delta_cfg="$HOME_SRC/dot_config/delta/catppuccin.gitconfig"
fetch_if_missing "$delta_cfg" \
  "https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig" \
  "delta catppuccin.gitconfig"
