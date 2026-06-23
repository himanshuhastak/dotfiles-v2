#!/usr/bin/env bash
# Hint when passwd login shell is not our self-built zsh (chsh is often restricted on clusters).
set -uo pipefail
source "$(dirname "$0")/../common.sh"

_df_zsh="$DOTFILES_DIR/var/tools/bin/zsh"
[ -x "$_df_zsh" ] || { skip "default shell (self-built zsh not installed)"; exit 0; }

login_shell=""
if command -v getent >/dev/null 2>&1; then
  login_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7-)"
elif [ -r /etc/passwd ]; then
  login_shell="$(awk -F: -v u="$USER" '$1==u {print $7}' /etc/passwd)"
fi

[ -n "$login_shell" ] || { skip "default shell (cannot read passwd entry)"; exit 0; }

login_shell="$(readlink -f "$login_shell" 2>/dev/null || printf '%s' "$login_shell")"
_df_zsh_resolved="$(readlink -f "$_df_zsh" 2>/dev/null || printf '%s' "$_df_zsh")"

if [ "$login_shell" = "$_df_zsh_resolved" ]; then
  ok "login shell -> $_df_zsh"
  exit 0
fi

warn "passwd login shell is $login_shell (not self-built zsh)"
printf '  interactive sessions still re-exec to %s when possible\n' "$_df_zsh"
printf '  to set login shell (if allowed):  chsh -s %s\n' "$_df_zsh"
