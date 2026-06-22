#!/usr/bin/env bash
# Back up all dotfiles-managed state into a timestamped folder, and optionally
# clear it so `install.sh` can set everything up from scratch.
#
#   install/cleanup.sh [--backup-only] [--hard] [--yes] [--dry-run]
#
#   (default)       back up, then RESET: unstow symlinks + remove generated
#                   caches/history and the local overrides dir, so the next
#                   `install.sh` (or scripts/stow-dotfiles.sh) starts fresh.
#   --backup-only   only create the backup; change nothing else
#   --hard          full wipe: ALSO back up + remove the generated var/ tree
#                   (built tools, plugin clones, caches) and .zwc bytecode, so
#                   the next install rebuilds absolutely everything
#   --yes, -y       skip the confirmation prompt before reset
#   --dry-run, -n   print what would happen; change nothing
#
# What is NEVER touched: the repo's tracked files. By default the built tools
# (var/tools/) and plugin clones (var/vendor/) are KEPT (expensive to rebuild);
# pass --hard to back up and clear those too. Restore a backup with the
# generated <backup>/restore.sh.
set -uo pipefail
source "$(dirname "$0")/common.sh"

RESET=1; ASSUME_YES=0; DRY=0; HARD=0
for a in "$@"; do
  case "$a" in
    --backup-only)  RESET=0 ;;
    --hard)         HARD=1 ;;
    --yes|-y)       ASSUME_YES=1 ;;
    --dry-run|-n)   DRY=1 ;;
    -h|--help)      sed -n '2,20p' "$0"; exit 0 ;;
    *)              warn "unknown arg: $a" ;;
  esac
done

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
LOCAL_DIR="${DOTFILES_LOCAL:-$DOTFILES/local}"

TS="$(date +%Y%m%d_%H%M%S)"
DEST="${DOTFILES_BACKUP_ROOT:-$HOME/.dotfiles-backups}/$TS"
MANIFEST="$DEST/manifest.txt"

act() { # run a mutating command unless --dry-run
  if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else eval "$@"; fi
}

# Generated state + local overrides (real files we DO want to preserve + clear).
state_paths=(
  "$HOME/.zcompdump" "$HOME/.zcompdump.zwc"
  "$HOME/.zsh_history"
  "$XDG_CACHE_HOME/zsh"
  "$XDG_CACHE_HOME/dotfiles"
  "$XDG_STATE_HOME/zsh"
  "$LOCAL_DIR"
  "$HOME/.zshrc.$USER"
)

# --hard only: the generated/downloaded tree (built tools, plugin clones,
# caches). Normally preserved because it is expensive to rebuild.
hard_paths=()
if [ "$HARD" -eq 1 ]; then
  hard_paths=( "$DOTFILES/var" )
fi

# ---------------------------------------------------------------------------
# 1) Backup
# ---------------------------------------------------------------------------
log "Backing up dotfiles state -> $DEST"
act "mkdir -p \"$DEST/home\""
[ "$DRY" -eq 1 ] || : > "$MANIFEST"
note() { [ "$DRY" -eq 1 ] && echo "  [dry-run] note: $*" || printf '%s\n' "$*" >> "$MANIFEST"; }

note "# dotfiles backup $TS"
note "# HOME=$HOME  DOTFILES=$DOTFILES"
note ""

backup_path() { # copy a real file/dir into DEST/home preserving its $HOME-relative path
  local p="$1" rel d
  case "$p" in "$HOME"/*) rel="${p#"$HOME"/}" ;; *) rel="$p" ;; esac
  if [ -L "$p" ]; then
    note "symlink  $p -> $(readlink "$p")"      # repo-owned; recreated by stow
  elif [ -e "$p" ]; then
    d="$DEST/home/$rel"
    act "mkdir -p \"$(dirname "$d")\""
    act "cp -a \"$p\" \"$d\""
    note "backup   $rel"
  fi
}

# 1a) stow-managed targets: real files get copied; symlinks are just recorded
#     (their content lives in the repo and is recreated by stow on reinstall).
note "## stow packages: $(discover_packages | tr '\n' ' ')"
for pkg in $(discover_packages); do
  while IFS= read -r rel; do
    rel="${rel#./}"
    backup_path "$HOME/$rel"
  done < <(cd "$STOW_DIR/$pkg" && find . -mindepth 1 \( -type f -o -type l \))
done
note ""

# 1b) generated state + local overrides
note "## generated state + local overrides"
for p in "${state_paths[@]}"; do backup_path "$p"; done

# 1c) --hard: the generated var/ tree (can be large: tools + plugin clones)
if [ "$HARD" -eq 1 ]; then
  note ""
  note "## --hard: generated var/ tree (tools, vendor, caches)"
  for p in "${hard_paths[@]}"; do backup_path "$p"; done
fi

# 1d) restore helper
if [ "$DRY" -eq 0 ]; then
  cat > "$DEST/restore.sh" <<'EOF'
#!/usr/bin/env bash
# Restore this backup's captured files back into $HOME.
# (Repo-owned symlinks are NOT restored here — re-run install.sh / stow for those.)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$here/home" ]; then
  cp -a "$here/home/." "$HOME/"
  echo "restored $here/home -> $HOME"
else
  echo "nothing to restore (no home/ in backup)"
fi
EOF
  chmod +x "$DEST/restore.sh"
fi
ok "Backup ready: $DEST"

# ---------------------------------------------------------------------------
# 2) Reset (optional)
# ---------------------------------------------------------------------------
if [ "$RESET" -eq 0 ]; then
  echo
  ok "Backup-only: nothing removed."
  echo "  Reset later with:  install/cleanup.sh --yes"
  exit 0
fi

echo
warn "RESET will unstow all symlinks and DELETE generated caches/history and:"
warn "  $LOCAL_DIR"
if [ "$HARD" -eq 1 ]; then
  warn "  $DOTFILES/var   (built tools, plugin clones, caches)   [--hard]"
  warn "  all .zwc bytecode under config/                        [--hard]"
  warn "Everything will be rebuilt from scratch on the next install."
else
  warn "Tools (var/tools/) and plugin clones (var/vendor/) are kept."
fi
warn "Backup: $DEST"
if [ "$DRY" -eq 0 ] && [ "$ASSUME_YES" -eq 0 ]; then
  printf 'Type "yes" to proceed: '
  read -r reply
  [ "$reply" = "yes" ] || { warn "aborted (backup kept)"; exit 0; }
fi

# 2a) unstow packages (safely removes stow's symlinks, incl. folded dirs)
if [ -x "$STOW" ]; then
  pkgs="$(discover_packages | tr '\n' ' ')"
  act "\"$STOW\" -D -d \"$STOW_DIR\" -t \"$HOME\" $pkgs" || warn "stow -D reported issues"
else
  warn "stow not built ($STOW); skipping unstow — run scripts/install-stow.sh"
fi

# 2b) remove generated state + local overrides (already backed up)
for p in "${state_paths[@]}"; do
  if [ -e "$p" ] || [ -L "$p" ]; then act "rm -rf \"$p\""; fi
done

# 2c) --hard: remove the generated var/ tree + compiled bytecode
if [ "$HARD" -eq 1 ]; then
  for p in "${hard_paths[@]}"; do
    if [ -e "$p" ] || [ -L "$p" ]; then act "rm -rf \"$p\""; fi
  done
  act "find \"$DOTFILES/config\" -name '*.zwc' -delete"
fi

echo
ok "Reset complete. Start fresh with:"
echo "  ./install.sh                       # full bootstrap (tools already cached)"
echo "  install/steps/stow-dotfiles.sh     # just re-link dotfiles"
echo "Restore this state instead:  $DEST/restore.sh"
