# config/shell/lib/x11-forwarding.sh — X11 xauth for login shells (SSH, LSF, GDM).
# Runs from $ZDOTDIR/.zprofile when DISPLAY is set (every login zsh, with or without LSF).
#
# Problems solved:
#   - SSH -X stores cookies under localhost/unix:N; LSF rewrites DISPLAY to submit-host:N
#   - GDM sets XAUTHORITY=/run/user/UID/gdm/Xauthority (breaks on LSF compute nodes)
#   - Linux clients often need MIT cookie family ffff

# Pick $HOME/.Xauthority (NFS-safe) when needed; merge cookies from the old file.
# Prints the resolved path on stdout.
normalize_x11_authority() {
  local home_auth="$HOME/.Xauthority"
  local cur="${XAUTHORITY:-}"
  local remote=0

  [ -n "${LSB_JOBID:-}" ] || [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_CLIENT:-}" ] &&
    remote=1

  case "$cur" in
    /run/user/*/gdm/* | /var/run/gdm/*) remote=1 ;;
  esac

  # Pure local desktop: keep a working non-gdm session file.
  if [ "$remote" -eq 0 ] && [ -n "$cur" ] && [ -r "$cur" ] && [ -w "$cur" ] &&
    xauth -f "$cur" list >/dev/null 2>&1; then
    printf '%s' "$cur"
    return 0
  fi

  if [ -n "$cur" ] && [ "$cur" != "$home_auth" ] && [ -r "$cur" ] &&
    command -v xauth >/dev/null 2>&1; then
    touch "$home_auth" 2>/dev/null || true
    xauth -f "$home_auth" merge "$cur" 2>/dev/null || true
  fi
  printf '%s' "$home_auth"
}

apply_x11_forwarding_fix() {
  [ -n "${DISPLAY:-}" ] || return 0
  command -v xauth >/dev/null 2>&1 || return 1

  local auth
  auth="$(normalize_x11_authority)"
  export XAUTHORITY="$auth"

  [ -f "$auth" ] && cp -p "$auth" "${auth}.bak" 2>/dev/null || true
  touch "$auth" 2>/dev/null || return 1

  # ffff-encoded entries alone may not satisfy all clients — always add hostname:N.
  local cookie
  cookie="$(xauth -f "$auth" list 2>/dev/null |
    awk '/MIT-MAGIC-COOKIE-1/ { print $3; exit }')"
  if [ -n "$cookie" ]; then
    xauth -f "$auth" add "$DISPLAY" . MIT-MAGIC-COOKIE-1 "$cookie" 2>/dev/null || true
  fi

  # SSH forwarded cookies often need family ffff on Linux.
  xauth -f "$auth" nlist "$DISPLAY" 2>/dev/null |
    sed -e 's/^..../ffff/' |
    xauth -f "$auth" nmerge - 2>/dev/null || true

  return 0
}
