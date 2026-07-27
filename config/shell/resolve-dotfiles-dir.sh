# config/shell/resolve-dotfiles-dir.sh — derive DOTFILES_DIR from chezmoi-managed paths.
[ -n "${DOTFILES_DIR:-}" ] && return 0

_dotfiles_dir_from_path() {
  _f="$1"
  [ -e "$_f" ] || return 1
  _f="$(readlink -f "$_f" 2>/dev/null)" || return 1
  case "$_f" in
    */home/dot_* | */home/.zshenv | */home/.bashrc)
      _root="${_f%/home/*}"
      [ -d "$_root/config/zsh" ] && DOTFILES_DIR="$_root" && return 0
      ;;
    */home/*)
      _root="${_f%/home/*}"
      [ -d "$_root/config/zsh" ] && DOTFILES_DIR="$_root" && return 0
      ;;
  esac
  return 1
}

if [ -n "${1:-}" ]; then
  _dotfiles_dir_from_path "$1" || true
else
  _dotfiles_dir_from_path "$HOME/.zshenv" ||
    _dotfiles_dir_from_path "$HOME/.bashrc" || true
fi

export DOTFILES_DIR
unset _f _root _dotfiles_dir_from_path
