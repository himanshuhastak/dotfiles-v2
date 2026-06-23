#!/usr/bin/env bash
# Warn when git user.name / user.email are not configured.
set -uo pipefail
source "$(dirname "$0")/../common.sh"

command -v git >/dev/null 2>&1 || { skip "git identity (git not found)"; exit 0; }

name="$(git config --global user.name 2>/dev/null || true)"
email="$(git config --global user.email 2>/dev/null || true)"

if [ -n "$name" ] && [ -n "$email" ]; then
  ok "git identity: $name <$email>"
  exit 0
fi

warn "git identity not fully configured:"
[ -z "$name" ] && printf '  git config --global user.name "Your Name"\n'
[ -z "$email" ] && printf '  git config --global user.email "you@example.com"\n'
