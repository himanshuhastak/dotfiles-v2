# config/shell/lib/x11-forwarding.sh — fix SSH X11 forwarding xauth cookies.
# Sourced from install/steps/fix-x11-forwarding.sh and login zsh (.zprofile).
apply_x11_forwarding_fix() {
  [ -n "${DISPLAY:-}" ] || return 0
  command -v xauth >/dev/null 2>&1 || return 1

  local auth="${XAUTHORITY:-$HOME/.Xauthority}"
  [ -f "$auth" ] && cp -p "$auth" "${auth}.bak" 2>/dev/null || true
  touch "$auth"
  xauth nlist "$DISPLAY" 2>/dev/null \
    | sed -e 's/^..../ffff/' \
    | xauth -f "$auth" nmerge - 2>/dev/null || return 1
  export XAUTHORITY="$auth"
  return 0
}
