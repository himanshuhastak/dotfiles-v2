#!/usr/bin/env bash
# Install tools from the manifest (config/tools.toml).
# This is a wrapper around install/bin/install-from-manifest.sh that supports
# both manifest-based installation and legacy per-tool script fallback.
set -uo pipefail

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$SCRIPTS/.."
BIN_DIR="$INSTALL_DIR/bin"
MANIFEST="$SCRIPTS/../../config/tools.toml"

# Try manifest-based installation first
if [ -f "$MANIFEST" ] && [ -x "$BIN_DIR/install-from-manifest.sh" ]; then
  bash "$BIN_DIR/install-from-manifest.sh"
else
  # Fallback to legacy per-tool script installation for backward compatibility
  source "$INSTALL_DIR/common.sh"
  init_tools_dir
  TOOLSD="$INSTALL_DIR/tools"
  
  # Stable, dependency-aware order
  order="fzf eza fd sd bat delta duf gdu just jq yq choose rg zoxide broot procs dust \
tldr lazygit atuin direnv bugwarrior parallel starship zsh sheldon zellij bash oc-rsync miniserve pipr \
shellcheck shfmt bats zshellcheck betterleaks actionlint editorconfig-checker"
  
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
  
  if [ -n "$failed" ]; then
    printf '\n' >&2
    warn "failed:$failed"
    exit 1
  fi
fi
