#!/usr/bin/env bash
# Link OpenSSH Include snippets; run after migrate-ssh-profile when needed.
set -uo pipefail
source "$(dirname "$0")/../common.sh"

LOCAL_DIR="${DOTFILES_LOCAL:-$DOTFILES/local}"
ssh_dir="$HOME/.ssh"
config_d="$ssh_dir/config.d"
dotfiles_snippet="$STOW_DIR/ssh/.ssh/config.d/dotfiles.conf"
local_src="$LOCAL_DIR/profile/ssh.local"
local_dest="$config_d/local.conf"

mkdir -p "$ssh_dir" "$config_d" "$ssh_dir/sockets"
chmod 700 "$ssh_dir"
chmod 700 "$ssh_dir/sockets" 2>/dev/null || true

link_snippet() {
  local src="$1" dest="$2" label="$3"
  [ -r "$src" ] || { warn "ssh: missing $src"; return 0; }

  local src_r dest_r
  src_r="$(readlink -f "$src" 2>/dev/null || echo "$src")"
  if [ -L "$dest" ]; then
    dest_r="$(readlink -f "$dest" 2>/dev/null || true)"
    [ "$dest_r" = "$src_r" ] && { ok "$label already linked"; return 0; }
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    skip "$label ($dest exists — not replacing)"
    return 0
  fi
  ln -s "$src" "$dest"
  ok "$label -> $dest"
}

link_snippet "$dotfiles_snippet" "$config_d/dotfiles.conf" "ssh dotfiles.conf"

if [ -r "$local_src" ]; then
  link_snippet "$local_src" "$local_dest" "ssh local.conf"
else
  warn "ssh: missing $local_src (create from local/profile/ssh.local template)"
fi

main_cfg="$ssh_dir/config"
stowed_cfg="$STOW_DIR/ssh/.ssh/config"
if [ -L "$main_cfg" ]; then
  ok "~/.ssh/config already stowed"
elif [ ! -e "$main_cfg" ] && [ -r "$stowed_cfg" ]; then
  ln -s "$stowed_cfg" "$main_cfg"
  chmod 600 "$main_cfg"
  ok "~/.ssh/config -> dotfiles"
elif [ -f "$main_cfg" ]; then
  if grep -q 'config\.d/dotfiles\.conf' "$main_cfg" 2>/dev/null; then
    ok "~/.ssh/config already Includes dotfiles.conf"
  else
    warn "ssh: run dotfiles ssh-migrate then dotfiles ssh-sync"
  fi
fi

[ -f "$main_cfg" ] && chmod 600 "$main_cfg"
chmod 600 "$config_d/dotfiles.conf" 2>/dev/null || true
chmod 600 "$local_dest" 2>/dev/null || true
