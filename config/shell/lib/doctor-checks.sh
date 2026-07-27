# config/shell/lib/doctor-checks.sh — shared health checks for dotfiles doctor.
# Sourced from bin/dotfiles (bash). Uses caller's chk/warn helpers when present.

_doctor_file_mode() {
  local path=$1
  [ -e "$path" ] || return 1
  stat -c '%a' "$path" 2>/dev/null || stat -f '%OLp' "$path" 2>/dev/null
}

_doctor_ssh_checks() {
  local ssh_dir="$HOME/.ssh" auth_keys="$ssh_dir/authorized_keys"
  local mode keys_found=0 pub missing=0 f pub_line

  if [ ! -d "$ssh_dir" ]; then
    printf '  %s·%s no ~/.ssh (optional; run install or ssh-keygen)\n' "${c_b:-}" "${c_r:-}"
    return 0
  fi

  mode="$(_doctor_file_mode "$ssh_dir")"
  if [ "$mode" = 700 ]; then
    chk "SSH dir mode 700" true
  else
    printf '  %s✘%s SSH dir mode %s (want 700) — run install or: chmod 700 ~/.ssh\n' \
      "${c_off:-}" "${c_r:-}" "${mode:-?}"
    bad=$((bad + 1))
  fi

  for f in "$ssh_dir"/id_*; do
    [ -f "$f" ] || continue
    case "$f" in *.pub) continue ;; esac
    keys_found=$((keys_found + 1))
    mode="$(_doctor_file_mode "$f")"
    if [ "$mode" != 600 ]; then
      printf '  %s✘%s %s mode %s (want 600)\n' "${c_off:-}" "${c_r:-}" "${f##*/}" "${mode:-?}"
      bad=$((bad + 1))
    fi
  done

  if [ "$keys_found" -eq 0 ]; then
    printf '  %s·%s no SSH private key in ~/.ssh\n' "${c_b:-}" "${c_r:-}"
  else
    chk "SSH private key(s) present ($keys_found)" true
  fi

  if [ -f "$auth_keys" ]; then
    mode="$(_doctor_file_mode "$auth_keys")"
    [ "$mode" = 600 ] && chk "authorized_keys mode 600" true || {
      printf '  %s✘%s authorized_keys mode %s (want 600)\n' "${c_off:-}" "${c_r:-}" "${mode:-?}"
      bad=$((bad + 1))
    }
  fi

  for pub in "$ssh_dir"/*.pub; do
    [ -f "$pub" ] || continue
    pub_line="$(tr -d '\r' <"$pub")"
    [ -n "$pub_line" ] || continue
    if [ -f "$auth_keys" ] && grep -qxF "$pub_line" "$auth_keys" 2>/dev/null; then
      :
    else
      missing=$((missing + 1))
    fi
  done

  if [ "$keys_found" -gt 0 ] && [ "$missing" -eq 0 ]; then
    chk "authorized_keys contains all local .pub keys" true
  elif [ "$missing" -gt 0 ]; then
    printf '  %s✘%s %d .pub key(s) missing from authorized_keys — run install or fix-ssh.sh\n' \
      "${c_off:-}" "${c_r:-}" "$missing"
    bad=$((bad + 1))
  fi
}

_doctor_git_checks() {
  command -v git >/dev/null 2>&1 || return 0
  local name email
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"
  if [ -n "$name" ] && [ -n "$email" ]; then
    chk "git identity configured" true
    printf '  %s·%s %s <%s>\n' "${c_b:-}" "${c_r:-}" "$name" "$email"
  else
    printf '  %s✘%s git identity incomplete — run: git config --global user.name/email\n' \
      "${c_off:-}" "${c_r:-}"
    bad=$((bad + 1))
  fi
}

_doctor_xdg_checks() {
  local d mode
  for d in \
    "${XDG_CONFIG_HOME:-$HOME/.config}:700" \
    "${XDG_CACHE_HOME:-$HOME/.cache}:700" \
    "${XDG_DATA_HOME:-$HOME/.local/share}:755" \
    "${XDG_STATE_HOME:-$HOME/.local/state}:700"; do
    local path="${d%%:*}" want="${d##*:}"
    [ -d "$path" ] || {
      printf '  %s✘%s missing %s\n' "${c_off:-}" "${c_r:-}" "$path"
      bad=$((bad + 1))
      continue
    }
    mode="$(_doctor_file_mode "$path")"
    if [ "$mode" = "$want" ]; then
      chk "$path mode $want" true
    else
      printf '  %s✘%s %s mode %s (want %s)\n' "${c_off:-}" "${c_r:-}" "$path" "${mode:-?}" "$want"
      bad=$((bad + 1))
    fi
  done
}

_doctor_x11_checks() {
  [ -n "${DISPLAY:-}" ] || return 0
  local auth="${XAUTHORITY:-$HOME/.Xauthority}"
  if [ -r "$auth" ]; then
    chk "XAUTHORITY readable ($auth)" true
  else
    printf '  %s✘%s XAUTHORITY missing ($auth) with DISPLAY=$DISPLAY\n' "${c_off:-}" "${c_r:-}" "$DISPLAY"
    bad=$((bad + 1))
  fi
  command -v xauth >/dev/null 2>&1 || return 0
  if xauth -f "$auth" list 2>/dev/null | grep -q .; then
    chk "xauth cookies present" true
  else
    printf '  %s✘%s no xauth cookies — reconnect with ssh -X or run fix-x11-forwarding\n' \
      "${c_off:-}" "${c_r:-}"
    bad=$((bad + 1))
  fi
}
