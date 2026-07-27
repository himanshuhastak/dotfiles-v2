#!/usr/bin/env bash
# Remove JetBrains Mono Nerd Font files from $FONT_DIR.
# Manual only — install-fonts.sh installs every font in nerdfonts/, including
# JetBrains. Run when you want to drop JetBrains from $FONT_DIR:
#   install/steps/remove-jetbrains-font.sh
set -euo pipefail
source "$(dirname "$0")/../common.sh"

removed=0
shopt -s nullglob
for f in "$FONT_DIR"/JetBrainsMono*; do
  [ -f "$f" ] || continue
  log "Removing $(basename "$f")"
  rm -f "$f"
  removed=$((removed + 1))
done
shopt -u nullglob

if [ "$removed" -gt 0 ]; then
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  ok "Removed $removed JetBrains Mono file(s) from $FONT_DIR"
else
  skip "JetBrains Mono Nerd Font (not installed)"
fi
