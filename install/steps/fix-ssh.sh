#!/usr/bin/env bash
# Ensure ~/.ssh exists, permissions are correct, and local .pub keys are in authorized_keys.
set -uo pipefail
source "$(dirname "$0")/../common.sh"

ssh_dir="$HOME/.ssh"
auth_keys="$ssh_dir/authorized_keys"
keys_found=0
added=0

if [ ! -d "$ssh_dir" ]; then
  mkdir -p "$ssh_dir"
  log "Created $ssh_dir"
fi
chmod 700 "$ssh_dir"

# OpenSSH-recommended permissions.
for f in "$ssh_dir"/id_*; do
  [ -f "$f" ] || continue
  case "$f" in
    *.pub) chmod 644 "$f" ;;
    *)     chmod 600 "$f"; keys_found=$((keys_found + 1)) ;;
  esac
done
for f in "$ssh_dir"/*.pub; do
  [ -f "$f" ] || continue
  chmod 644 "$f"
done
[ -f "$auth_keys" ] && chmod 600 "$auth_keys"
[ -f "$ssh_dir/config" ] && chmod 600 "$ssh_dir/config"
[ -f "$ssh_dir/known_hosts" ] && chmod 644 "$ssh_dir/known_hosts"
ok "SSH directory permissions ($ssh_dir)"

if [ "$keys_found" -eq 0 ]; then
  warn "no SSH private key in $ssh_dir (run: ssh-keygen -t ed25519 -f $ssh_dir/id_ed25519)"
else
  ok "SSH private key(s) present ($keys_found)"
fi

touch "$auth_keys"
chmod 600 "$auth_keys"

for pub in "$ssh_dir"/*.pub; do
  [ -f "$pub" ] || continue
  pub_line="$(tr -d '\r' <"$pub")"
  [ -n "$pub_line" ] || continue
  if grep -qxF "$pub_line" "$auth_keys" 2>/dev/null; then
    ok "$(basename "$pub") already in authorized_keys"
  else
    printf '%s\n' "$pub_line" >>"$auth_keys"
    ok "added $(basename "$pub") to authorized_keys"
    added=$((added + 1))
  fi
done

[ "$keys_found" -gt 0 ] && [ "$added" -eq 0 ] && \
  ok "authorized_keys contains all local .pub keys"
