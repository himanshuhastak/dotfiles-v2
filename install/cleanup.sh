#!/usr/bin/env bash
# Backup local state; optionally remove chezmoi-managed files and overrides.
#   install/cleanup.sh [--backup-only] [--hard] [--yes] [--dry-run]
set -uo pipefail
source "$(dirname "$0")/common.sh"

RESET=1
ASSUME_YES=0
DRY=0
HARD=0
for a in "$@"; do
  case "$a" in
    --backup-only) RESET=0 ;;
    --hard) HARD=1 ;;
    --yes | -y) ASSUME_YES=1 ;;
    --dry-run | -n) DRY=1 ;;
    -h | --help)
      sed -n '2,5p' "$0"
      exit 0
      ;;
    *) warn "unknown arg: $a" ;;
  esac
done

LOCAL_DIR="${DOTFILES_LOCAL:-$DOTFILES/local}"
TS="$(date +%Y%m%d_%H%M%S)"
DEST="${DOTFILES_BACKUP_ROOT:-$HOME/.dotfiles-backups}/$TS"
act() { [ "$DRY" -eq 1 ] && echo "  [dry-run] $*" || eval "$@"; }

log "Backup -> $DEST"
act mkdir -p "$DEST/home"
if [ -d "$DOTFILES/home" ]; then
  while IFS= read -r rel; do
    rel="${rel#./}"
    [ -f "$HOME/$rel" ] && act "cp -a '$HOME/$rel' '$DEST/home/$rel'"
  done < <(cd "$DOTFILES/home" && find . -type f ! -name '*.tmpl')
fi
act "cp -a '$LOCAL_DIR' '$DEST/local' 2>/dev/null || true"
ok "Backup: $DEST"

[ "$RESET" -eq 0 ] && exit 0
if [ "$DRY" -eq 0 ] && [ "$ASSUME_YES" -eq 0 ]; then
  read -r -p "Type yes to reset: " r
  [ "$r" = yes ] || exit 0
fi

if command -v chezmoi >/dev/null 2>&1 || [ -x "$DOTFILES/var/tools/bin/chezmoi" ]; then
  bin="$DOTFILES/var/tools/bin/chezmoi"
  [ -x "$bin" ] || bin="$(command -v chezmoi)"
  # Legacy: entire repo was wrongly applied before source was scoped to home/
  act "$bin" --persistent-state "$DOTFILES/var/cache/chezmoi-state.json" \
    --source "$DOTFILES" destroy --force 2>/dev/null || true
  act "$bin" --persistent-state "$DOTFILES/var/cache/chezmoi-state.json" \
    --source "$DOTFILES/home" destroy --force 2>/dev/null || true
fi
act "rm -rf '$LOCAL_DIR'"
[ "$HARD" -eq 1 ] && act "rm -rf '$DOTFILES/var'"
ok "Reset complete — run: ./install.sh"
