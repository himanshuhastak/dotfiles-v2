#!/usr/bin/env bash
# Make the taskwarrior/timewarrior hook executable after stow.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

hook="$HOME/.task/hooks/on-modify.timewarrior"
if [ -e "$hook" ] && [ ! -x "$hook" ]; then
  chmod +x "$hook"
  ok "task/timew hook executable"
else
  skip "task/timew hook"
fi
