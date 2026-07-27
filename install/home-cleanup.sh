#!/usr/bin/env bash
# Remove chezmoi-managed junk from a bad apply (whole repo deployed to $HOME).
# Safe to run before dotfiles apply with the fixed home/ source.
set -uo pipefail

DOTFILES="${DOTFILES:-$(cd "$(dirname "$0")/.." && pwd)}"
CHEZMOI="$DOTFILES/var/tools/bin/chezmoi"
[ -x "$CHEZMOI" ] || CHEZMOI="$(command -v chezmoi 2>/dev/null || true)"

log() { printf '==> %s\n' "$*"; }

if [ -n "$CHEZMOI" ]; then
  log "chezmoi destroy (legacy repo-root source)"
  "$CHEZMOI" --persistent-state "$DOTFILES/var/cache/chezmoi-state.json" \
    --source "$DOTFILES" destroy --force 2>/dev/null || true
  log "chezmoi destroy (home/ source)"
  "$CHEZMOI" --persistent-state "$DOTFILES/var/cache/chezmoi-state.json" \
    --source "$DOTFILES/home" destroy --force 2>/dev/null || true
fi

for junk in config bin tools install docs man test LICENSE justfile README.md install.sh betterleaks.toml home; do
  [ -e "$HOME/$junk" ] && rm -rf "$HOME/$junk" && log "removed ~/$junk"
done

log "done — run: dotfiles apply && exec zsh -l"
