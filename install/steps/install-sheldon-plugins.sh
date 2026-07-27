#!/usr/bin/env bash
# Clone zsh plugins from home/.config/sheldon/plugins.toml into var/vendor (gitignored).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

cfg_dir="$DOTFILES/home/dot_config/sheldon"
have sheldon || {
  warn "sheldon not installed (run install-tools)"
  exit 1
}
[ -f "$cfg_dir/plugins.toml" ] || {
  warn "missing $cfg_dir/plugins.toml"
  exit 1
}

export SHELDON_CONFIG_DIR="$cfg_dir"
export SHELDON_DATA_DIR="$DOTFILES/var/vendor"
mkdir -p "$SHELDON_DATA_DIR"
log "sheldon lock -> $SHELDON_DATA_DIR"
if sheldon lock; then
  ok "zsh plugins cloned"
else
  warn "sheldon lock failed (no GitHub access?) — re-run later"
fi

zd="$SHELDON_DATA_DIR/zsh-defer"
if [ -r "$zd/zsh-defer.plugin.zsh" ]; then
  skip "zsh-defer (already cloned)"
elif command -v git >/dev/null 2>&1 &&
  git clone --depth 1 https://github.com/romkatv/zsh-defer "$zd" 2>/dev/null; then
  ok "zsh-defer -> $zd"
else
  warn "zsh-defer clone failed — async startup falls back to synchronous"
fi
