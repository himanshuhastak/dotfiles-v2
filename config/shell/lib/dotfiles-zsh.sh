# config/shell/lib/dotfiles-zsh.sh — resolve the self-built zsh binary (POSIX).
# Usage: . this file, then dotfiles_self_zsh_bin || fallback=...

dotfiles_self_zsh_bin() {
  local root="${DOTFILES_DIR:-}"
  [ -n "$root" ] && [ -x "$root/var/tools/bin/zsh" ] && {
    printf '%s\n' "$root/var/tools/bin/zsh"
    return 0
  }
  return 1
}

# Running zsh binary path (Linux: /proc/self/exe; else ZSH_ARGZERO when zsh).
dotfiles_current_zsh_bin() {
  if [ -r /proc/self/exe ]; then
    readlink -f /proc/self/exe 2>/dev/null && return 0
  fi
  [ -n "${ZSH_ARGZERO:-}" ] && printf '%s\n' "$ZSH_ARGZERO" && return 0
  return 1
}
