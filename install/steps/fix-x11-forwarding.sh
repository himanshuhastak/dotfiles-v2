#!/usr/bin/env bash
# Apply XAUTH patch for SSH X11 forwarding (also runs on each zsh login via .zprofile).
set -uo pipefail
source "$(dirname "$0")/../common.sh"

lib="$DOTFILES/config/shell/lib/x11-forwarding.sh"
[ -r "$lib" ] || { warn "X11: missing $lib"; exit 0; }
# shellcheck disable=SC1090
source "$lib"

if [ -z "${DISPLAY:-}" ]; then
  skip "X11 forwarding (no DISPLAY — runs automatically on SSH login with -X)"
  exit 0
fi

log "Applying XAUTH patch for DISPLAY=$DISPLAY"
if apply_x11_forwarding_fix; then
  ok "XAUTHORITY -> ${XAUTHORITY:-$HOME/.Xauthority}"
  command -v xauth >/dev/null 2>&1 && xauth -f "${XAUTHORITY:-$HOME/.Xauthority}" list 2>/dev/null | head -3
else
  warn "X11: xauth patch failed (is X11 forwarding enabled on this session?)"
fi
