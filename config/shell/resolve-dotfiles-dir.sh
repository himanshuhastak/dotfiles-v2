# config/shell/resolve-dotfiles-dir.sh — derive DOTFILES_DIR from stow paths (POSIX).
# Silent. Idempotent: no-op if DOTFILES_DIR is already set.
#
# Usage (dot-source):
#   . "$DOTFILES_DIR/config/shell/resolve-dotfiles-dir.sh" [path-under-config/stow/]
#
# With an explicit path (e.g. "${BASH_SOURCE[0]}" from stowed ~/.bashrc), walks up
# from .../config/stow/<pkg>/file to the repo root. Without an argument, tries
# $HOME/.zshenv and $HOME/.bashrc (the stow symlinks created by install).

[ -n "${DOTFILES_DIR:-}" ] && return 0

_dotfiles_dir_from_stow_file() {
  _f="$1"
  [ -e "$_f" ] || return 1
  _f="$(readlink -f "$_f" 2>/dev/null)" || return 1
  case "$_f" in
    */config/stow/*) ;;
    *) return 1 ;;
  esac
  _root="${_f%/config/stow/*}"
  [ -d "$_root/config/zsh" ] || return 1
  DOTFILES_DIR="$_root"
  return 0
}

if [ -n "${1:-}" ]; then
  _dotfiles_dir_from_stow_file "$1" || true
else
  _dotfiles_dir_from_stow_file "$HOME/.zshenv" || \
  _dotfiles_dir_from_stow_file "$HOME/.bashrc" || true
fi

: "${DOTFILES_DIR:=$HOME/dotfiles_v2}"
export DOTFILES_DIR

unset _f _root _dotfiles_dir_from_stow_file
