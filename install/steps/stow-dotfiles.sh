#!/usr/bin/env bash
# Symlink stow/<pkg>/... into $HOME via stow-python.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

[ -x "$STOW" ] || { warn "run scripts/install-stow.sh first"; exit 1; }

# stow-python doesn't adopt existing paths, so clear anything occupying a
# managed target that isn't already our link (regular files, stale/foreign
# symlinks). Then restow cleanly.
# Remove any ANCESTOR dir of $rel that is a stale/foreign symlink (e.g. an
# old folded directory link like ~/.config/atuin -> .../dotfiles/stow/...).
# Links already pointing into the current $STOW_DIR are left intact.
clear_stale_ancestors() {
  local rel="$1" path="$HOME" comp resolved
  local IFS=/
  for comp in $rel; do
    [ -n "$comp" ] || continue
    path="$path/$comp"
    [ "$path" = "$HOME/$rel" ] && break   # the leaf is handled by the caller
    if [ -L "$path" ]; then
      resolved="$(readlink -f "$path" 2>/dev/null || true)"
      case "$resolved" in
        "$STOW_DIR"/*) : ;;               # current fold → keep
        *) rm -f "$path" ;;               # stale/foreign fold → clear
      esac
    fi
  done
}

clean_conflicts() {
  local pkg rel target
  for pkg in $(discover_packages); do
    while IFS= read -r rel; do
      rel="${rel#./}"
      target="$HOME/$rel"
      clear_stale_ancestors "$rel"
      if [ -L "$target" ]; then
        # Resolve to an absolute path and keep only links that already point
        # into the CURRENT stow dir; clear stale (old-layout) or foreign links.
        resolved="$(readlink -f "$target" 2>/dev/null || true)"
        case "$resolved" in
          "$STOW_DIR/$pkg/"*) ;;          # already ours → keep
          *) rm -f "$target" ;;           # stale/foreign → clear
        esac
      elif [ -e "$target" ]; then
        # Parent dirs may already be stow symlinks; don't delete the repo source.
        resolved="$(readlink -f "$target" 2>/dev/null || true)"
        case "$resolved" in
          "$STOW_DIR"/*) continue ;;
        esac
        rm -f "$target"
      fi
    done < <(cd "$STOW_DIR/$pkg" && find . -mindepth 1 \( -type f -o -type l \)) || true
  done
}

# ssh / vnc: always stow managed files (keys, passwd, logs are NOT in packages).
# User machine config lives in local/profile/ (ssh.local) and is symlinked by ssh-sync.

PKGS=($(discover_packages))
[ "${#PKGS[@]}" -gt 0 ] || { warn "no stow packages in $STOW_DIR"; exit 1; }

clean_conflicts
log "Stowing: ${PKGS[*]}"
"$STOW" -R -d "$STOW_DIR" -t "$HOME" "${PKGS[@]}"
ok "dotfiles stowed"
