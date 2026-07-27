#!/usr/bin/env bash
# bugwarrior — now installed inside dotfiles-tools venv (unified).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

if [ -x "$BIN/bugwarrior-pull" ]; then
  skip bugwarrior
  exit 0
fi

# Delegate to dotfiles-tools installer (includes bugwarrior[keyring]).
tools_script="$(dirname "$0")/dotfiles-tools.sh"
[ -f "$tools_script" ] || {
  warn "bugwarrior: dotfiles-tools installer missing"
  exit 1
}
bash "$tools_script"
