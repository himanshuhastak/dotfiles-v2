#!/usr/bin/env bash
# Host setup: XDG dirs, SSH permissions, git identity, default shell, task hooks.
set -uo pipefail
source "$(dirname "$0")/../common.sh"

_cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
_data="${XDG_DATA_HOME:-$HOME/.local/share}"
_state="${XDG_STATE_HOME:-$HOME/.local/state}"

_ensure_dir() {
  local dir=$1 mode=$2
  mkdir -p "$dir"
  chmod "$mode" "$dir"
  ok "$dir (mode $mode)"
}

log "XDG directories"
_ensure_dir "$_cfg" 700
_ensure_dir "$_cache" 700
_ensure_dir "$_data" 755
_ensure_dir "$_state" 700
_ensure_dir "$_data/fonts" 755

log "SSH permissions"
ssh_dir="$HOME/.ssh"
mkdir -p "$ssh_dir/sockets"
chmod 700 "$ssh_dir" "$ssh_dir/sockets" 2>/dev/null || true
for f in "$ssh_dir"/id_*; do
  [ -f "$f" ] || continue
  case "$f" in *.pub) continue ;; esac
  chmod 600 "$f" 2>/dev/null || true
done
if [ -f "$ssh_dir/authorized_keys" ]; then chmod 600 "$ssh_dir/authorized_keys"; fi
for pub in "$ssh_dir"/*.pub; do
  [ -f "$pub" ] || continue
  pub_line="$(tr -d '\r' <"$pub")"
  [ -n "$pub_line" ] && [ -f "$ssh_dir/authorized_keys" ] &&
    grep -qxF "$pub_line" "$ssh_dir/authorized_keys" 2>/dev/null ||
    printf '%s\n' "$pub_line" >>"$ssh_dir/authorized_keys"
done
ok "~/.ssh ready"

if command -v git >/dev/null 2>&1; then
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"
  if [ -n "$name" ] && [ -n "$email" ]; then
    ok "git identity: $name <$email>"
  else
    warn "git identity incomplete — set: git config --global user.name / user.email"
  fi
fi

if [ -x "$BIN/zsh" ] && [ "${SHELL:-}" != "$BIN/zsh" ]; then
  if chsh -s "$BIN/zsh" 2>/dev/null; then ok "default shell -> $BIN/zsh"; else skip "chsh (run manually)"; fi
fi

task_hooks="$HOME/.task/hooks/on-modify.timewarrior"
if [ -x "$BIN/timew" ] && [ -r "$DOTFILES/home/.task/hooks/on-modify.timewarrior" ]; then
  mkdir -p "$(dirname "$task_hooks")"
  if [ ! -e "$task_hooks" ]; then
    cp "$DOTFILES/home/.task/hooks/on-modify.timewarrior" "$task_hooks"
    chmod +x "$task_hooks"
    ok "task timew hook installed"
  fi
fi
