#!/usr/bin/env bash
# Stow ~/Work/* — reads path:shortname lines from $DOTFILES_LOCAL/profile/mount.lst.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

LOCAL_DIR="${DOTFILES_LOCAL:-$DOTFILES/local}"
WORK_STOW_DIR="$DOTFILES/var/work"
WORK_PKG="$WORK_STOW_DIR/mounts"
WORK_TARGET="${DOTFILES_WORK_TARGET:-$HOME/Work}"

# Canonical: local/profile/mount.lst (same tree as secrets.sh, company.sh, …).
_resolve_mount_lst() {
  local base="${1:-$LOCAL_DIR}" f
  for f in "$base/profile/mount.lst" "$base/mount.lst"; do
    if [ -r "$f" ]; then
      [ "$f" = "$base/profile/mount.lst" ] || warn "work-stow: using legacy $f (prefer local/profile/mount.lst)"
      printf '%s\n' "$f"
      return 0
    fi
  done
  return 1
}

MOUNT_LST="$(_resolve_mount_lst)" || {
  warn "work-stow: no local/profile/mount.lst (path:shortname lines; see docs/INSTALL.md)"
  exit 0
}

_rel_link() {
  python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$1" "$2"
}

_resolve_mount_path() {
  local p="$1"
  p="$(eval echo "$p")"
  case "$p" in
    /scratch/*)
      [ -d "$p" ] || { [ -d /scratch ] && p=/scratch; }
      ;;
  esac
  printf '%s\n' "$p"
}

mkdir -p "$WORK_PKG"
_mount_n=0
while IFS= read -r _line || [ -n "$_line" ]; do
  _line="${_line%%#*}"
  _line="${_line#"${_line%%[![:space:]]*}"}"
  _line="${_line%"${_line##*[![:space:]]}"}"
  [ -n "$_line" ] || continue
  _path="${_line%%:*}"
  _name="${_line##*:}"
  [ -n "$_path" ] && [ -n "$_name" ] || die "work-stow: invalid line in $MOUNT_LST: '$_line' (want path:shortname)"
  _path="$(_resolve_mount_path "$_path")"
  ln -sfn "$(_rel_link "$_path" "$WORK_PKG")" "$WORK_PKG/$_name"
  _mount_n=$((_mount_n + 1))
done < "$MOUNT_LST"
[ "$_mount_n" -gt 0 ] || die "work-stow: no mounts in $MOUNT_LST"
unset _line _path _name _mount_n

mkdir -p "$WORK_TARGET"

clean_work_conflicts() {
  local rel target expected got
  while IFS= read -r rel; do
    rel="${rel#./}"
    target="$WORK_TARGET/$rel"
    expected="$(readlink -f "$WORK_PKG/$rel" 2>/dev/null || true)"
    [ -n "$expected" ] || continue
    if [ -L "$target" ]; then
      got="$(readlink -f "$target" 2>/dev/null || true)"
      [ "$got" = "$expected" ] && continue
      rm -f "$target"
    elif [ -e "$target" ]; then
      warn "skipping occupied path (not a symlink): $target"
    fi
  done < <(cd "$WORK_PKG" && find . -mindepth 1 \( -type f -o -type l \) 2>/dev/null)
}

clean_work_conflicts
log "Stowing work mounts -> $WORK_TARGET (from $MOUNT_LST)"
"$STOW" -R -d "$WORK_STOW_DIR" -t "$WORK_TARGET" mounts
ok "Work folder ready: $WORK_TARGET"
