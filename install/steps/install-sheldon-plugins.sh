#!/usr/bin/env bash
# Clone zsh plugins declared in stow/sheldon/.config/sheldon/plugins.toml
# into the vendored data dir (gitignored), via `sheldon lock`.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

# Read config straight from the repo (don't depend on the ~/.config symlink),
# and clone into the vendored data dir.
cfg_dir="$STOW_DIR/sheldon/.config/sheldon"
have sheldon || { warn "sheldon not installed (run scripts/tools/sheldon.sh)"; exit 1; }
[ -f "$cfg_dir/plugins.toml" ] || { warn "missing $cfg_dir/plugins.toml"; exit 1; }

export SHELDON_CONFIG_DIR="$cfg_dir"
export SHELDON_DATA_DIR="$DOTFILES/var/vendor"
mkdir -p "$SHELDON_DATA_DIR"
log "sheldon lock -> $SHELDON_DATA_DIR"
if sheldon lock; then
  ok "zsh plugins cloned"
else
  warn "sheldon lock failed (no GitHub access?) — re-run later"
fi

# zsh-defer (romkatv) — async/staged startup backend sourced by zsh/90-defer.zsh.
# Kept at a fixed path (not via sheldon) so 90-defer can source it BEFORE the
# sheldon plugins load. Missing => startup silently falls back to synchronous.
zd="$SHELDON_DATA_DIR/zsh-defer"
if [ -r "$zd/zsh-defer.plugin.zsh" ]; then
  skip "zsh-defer (already cloned)"
elif command -v git >/dev/null 2>&1 && \
     git clone --depth 1 https://github.com/romkatv/zsh-defer "$zd" 2>/dev/null; then
  ok "zsh-defer -> $zd"
else
  warn "zsh-defer clone failed — async startup falls back to synchronous"
fi
