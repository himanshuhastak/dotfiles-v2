# config/shell/core/10-functions.sh — portable functions (bash + zsh).

date_ist() { TZ=Asia/Calcutta date "$@"; }

bkup() {
  [ -e "$1" ] || { echo "Error: '$1' does not exist" >&2; return 1; }
  if [ -e "$1.bkp" ]; then
    local ts; ts=$(date_ist +%Y%m%d_%H%M%S)
    mv "$1.bkp" "$1.bkp_$ts" || return 1
    echo "Archived existing backup: $1.bkp -> $1.bkp_$ts"
  fi
  echo "Moving $1 to $1.bkp"; mv "$1" "$1.bkp"
}
bkp() {
  [ -e "$1" ] || { echo "Error: '$1' does not exist" >&2; return 1; }
  if [ -e "$1.bkp" ]; then
    local ts; ts=$(date_ist +%Y%m%d_%H%M%S)
    mv "$1.bkp" "$1.bkp_$ts" || return 1
    echo "Archived existing backup: $1.bkp -> $1.bkp_$ts"
  fi
  cp -rf "$1" "$1.bkp" && echo "Copied: $1 -> $1.bkp"
}
untar_file() {
  local file="$1"
  [ -z "$file" ] && { echo "Usage: untar_file <file>"; return 1; }
  case "$file" in
    *.tar.bz2) tar xvjf "$file" ;;
    *.tar.gz)  tar xvzf "$file" ;;
    *.tar.xz)  tar xvJf "$file" ;;
    *.tar)     tar xvf  "$file" ;;
    *.bz2)     bunzip2  "$file" ;;
    *.gz)      gunzip   "$file" ;;
    *.xz)      unxz     "$file" ;;
    *.zip)     unzip    "$file" ;;
    *)         echo "Unsupported file extension: $file" ;;
  esac
}
mkcd() { mkdir -pv "$1" && cd "$1" || return; }

# Smart cd: normal paths first; fall back to zoxide `z` for frecent dir names.
cd() {
  if [ $# -eq 0 ]; then builtin cd; return; fi
  if builtin cd "$@" 2>/dev/null; then return 0; fi
  if [ $# -eq 1 ] && command -v z >/dev/null 2>&1; then z "$1"; return; fi
  builtin cd "$@"
}

Calc() {
  local what="$*"
  python3 -c "from math import * ; print(f'{$what}')"
  python3 -c "from math import * ; print(f'{$what:,}')"
  python3 -c "from math import * ; print(f'{$what:X}')"
  python3 -c "from math import * ; print(f'{$what:b}')"
}
