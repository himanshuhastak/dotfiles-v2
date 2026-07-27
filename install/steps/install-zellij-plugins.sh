#!/usr/bin/env bash
# Download Zellij WASM plugins and link into home/.config/zellij/plugins/.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

FORCE=0
[ "${1:-}" = --force ] && FORCE=1

VENDOR="$DOTFILES/var/vendor/zellij-plugins"
HOME_PLUGINS="$DOTFILES/home/dot_config/zellij/plugins"
mkdir -p "$VENDOR" "$HOME_PLUGINS"

fetch_wasm() {
  local label=$1 repo=$2 asset=$3
  local tag ver url dest link
  tag="$(gh_latest_tag "$repo")"
  [ -n "$tag" ] || {
    warn "$label: cannot resolve latest release of $repo"
    return 1
  }
  ver="${tag#v}"
  url="https://github.com/$repo/releases/download/$tag/$asset"
  dest="$VENDOR/$asset"
  link="$HOME_PLUGINS/$asset"

  if [ -f "$dest" ] && [ "$FORCE" -eq 0 ]; then
    skip "$label $tag (use --force to refresh)"
  else
    log "Fetching $label $tag"
    curl -fsSL --retry 3 --connect-timeout 20 -o "$dest" "$url"
    ok "$label -> $dest"
  fi
  ln -sfn "$dest" "$link"
}

have zellij || warn "zellij not on PATH yet — downloading plugins anyway"

fetch_wasm zsm liam-mackie/zsm zsm.wasm
fetch_wasm zjstatus dj95/zjstatus zjstatus.wasm
fetch_wasm zjframes dj95/zjstatus zjframes.wasm
fetch_wasm monocle imsnif/monocle monocle.wasm

ok "zellij plugins -> $VENDOR (linked in home/dot_config/zellij/plugins)"
