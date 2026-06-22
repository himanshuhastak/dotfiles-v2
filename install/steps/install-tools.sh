#!/usr/bin/env bash
# Install every CLI tool by running each scripts/tools/<tool>.sh.
# Usage: install-tools.sh [tool ...]   (no args = all)
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS/../common.sh"
init_tools_dir
TOOLSD="$SCRIPTS/../tools"   # per-tool installers live in install/tools/

# Stable, dependency-aware order (starship/sheldon/zellij last is fine).
# `bash` builds the latest GNU bash (scripts/tools/bash.sh) — bash is only a
# script runner here, so its interactive add-ons are intentionally NOT installed.
order="fzf eza fd sd bat delta duf gdu just jq yq choose rg zoxide broot procs dust \
tldr lazygit atuin direnv bugwarrior parallel starship zsh sheldon zellij bash oc-rsync miniserve pipr \
shellcheck shfmt bats zshellcheck betterleaks actionlint editorconfig-checker"

# --- bash interactive add-ons: DISABLED ------------------------------------
# zsh is the interactive shell; bash only runs scripts, so we skip ble.sh (the
# bash line editor: syntax highlighting + autosuggestions). The installer
# (scripts/tools/blesh.sh) is kept — re-enable by appending its name to `order`:
#   blesh
# ---------------------------------------------------------------------------

tools=("$@")
[ "${#tools[@]}" -eq 0 ] && tools=($order)

failed=""
for t in "${tools[@]}"; do
  script="$TOOLSD/$t.sh"
  if [ ! -f "$script" ]; then
    warn "no installer for '$t'"
    failed="$failed $t"
    continue
  fi
  bash "$script" || failed="$failed $t"
done

echo
if [ -n "$failed" ]; then
  warn "failed:$failed"
  warn "re-run individually, e.g.:  scripts/tools/<tool>.sh"
  exit 1
fi
ok "all tools installed -> $BIN"
