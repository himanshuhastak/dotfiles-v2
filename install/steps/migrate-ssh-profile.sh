#!/usr/bin/env bash
# Migrate legacy ~/.ssh/config → local/profile/ssh.local when safe.
set -uo pipefail
source "$(dirname "$0")/../common.sh"

LOCAL_DIR="${DOTFILES_LOCAL:-$DOTFILES/local}"
ssh_local="$LOCAL_DIR/profile/ssh.local"
legacy_cfg="$HOME/.ssh/config"
backup="$HOME/.ssh/config.pre-dotfiles.bak"

[ -L "$legacy_cfg" ] && exit 0
[ -f "$legacy_cfg" ] && grep -q 'config\.d/dotfiles\.conf' "$legacy_cfg" 2>/dev/null && exit 0
[ -f "$backup" ] && exit 0
[ -f "$legacy_cfg" ] || exit 0

log "Migrating legacy SSH config"
cp -a "$legacy_cfg" "$backup"
extracted="$(awk '/^Host[[:space:]]/{h=$2;if(h=="github.com"||h=="gitlab.com"||h=="*"){skip=1;next}skip=0;print;next}skip==0{print}' "$legacy_cfg")"
[ -z "$extracted" ] && exit 0
mkdir -p "$(dirname "$ssh_local")"
[ ! -f "$ssh_local" ] && printf '%s\n' "$extracted" >"$ssh_local" && ok "created ssh.local"
