#!/usr/bin/env bash
# Move a legacy monolithic ~/.ssh/config into local/profile/ssh.local when safe.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

LOCAL_DIR="${DOTFILES_LOCAL:-$DOTFILES/local}"
ssh_local="$LOCAL_DIR/profile/ssh.local"
legacy_cfg="$HOME/.ssh/config"
legacy_win="$HOME/.ssh/config.windows"
backup="$HOME/.ssh/config.pre-dotfiles.bak"

# Already migrated or using Include layout
if [ -L "$legacy_cfg" ]; then
  exit 0
fi
if [ -f "$legacy_cfg" ] && grep -q 'config\.d/dotfiles\.conf' "$legacy_cfg" 2>/dev/null; then
  exit 0
fi
if [ -f "$backup" ]; then
  skip "ssh migrate: backup exists ($backup)"
  exit 0
fi

src=""
if [ -f "$legacy_cfg" ]; then
  src="$legacy_cfg"
elif [ -f "$legacy_win" ]; then
  src="$legacy_win"
else
  exit 0
fi

log "Migrating legacy SSH config → local/profile/ssh.local"
cp -a "$src" "$backup"
ok "backup -> $backup"

# Extract Host blocks that are NOT github/gitlab/Host * into ssh.local
extract_hosts() {
  awk '
    /^[[:space:]]*#/ { next }
    /^Host[[:space:]]/ {
      h=$2
      if (h == "github.com" || h == "gitlab.com" || h == "*") { skip=1; next }
      skip=0; print; next
    }
    skip==0 { print }
  ' "$src"
}

extracted="$(extract_hosts)"
if [ -z "$extracted" ]; then
  warn "ssh migrate: no work Host blocks found in $src"
  exit 0
fi

if [ ! -f "$ssh_local" ]; then
  printf '%s\n' "$extracted" >"$ssh_local"
  ok "created $ssh_local from legacy config"
  exit 0
fi

# Merge if ssh.local has only comments / placeholders
if grep -qE '10\.207\.|arctest5|res-vm-rhel' "$ssh_local" 2>/dev/null; then
  ok "ssh.local already has machine hosts — skip merge"
  exit 0
fi

{
  echo "# --- merged from legacy SSH config ($(date -Iseconds)) ---"
  printf '%s\n' "$extracted"
  echo ""
  cat "$ssh_local"
} >"${ssh_local}.new"
mv "${ssh_local}.new" "$ssh_local"
ok "merged legacy hosts into $ssh_local"
