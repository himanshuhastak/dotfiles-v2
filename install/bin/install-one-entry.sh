#!/usr/bin/env bash
# install/bin/install-one-entry.sh — install one tools.toml manifest row (parallel worker).
# Entry format: name|repo|archive_pattern|binname|install_method|optional|path_hint
set -uo pipefail

entry="${1:-}"
[ -n "$entry" ] || exit 0

DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"
export DOTFILES
# Never write downloads/scratch into the repo root (parallel workers inherit cwd).
cd "$DOTFILES/var/cache" 2>/dev/null || mkdir -p "$DOTFILES/var/cache" && cd "$DOTFILES/var/cache"

source "$DOTFILES/install/common.sh"

name="" repo="" archive_pattern="" binname="" install_method="" optional="" path_hint=""
IFS='|' read -r name repo archive_pattern binname install_method optional path_hint <<<"$entry"
[ -z "$repo" ] && exit 0

tools="$DOTFILES/install/tools"

if [ -n "$install_method" ] && [ "$install_method" != "github" ]; then
  script="$tools/${name}.sh"
  if [ -f "$script" ]; then
    bash "$script" || exit 1
  else
    warn "$name: install_method=$install_method but no installer at $script"
    exit 1
  fi
  exit 0
fi

if [ -f "$tools/${name}.sh" ]; then
  bash "$tools/${name}.sh" || exit 1
  exit 0
fi

if [ -z "$archive_pattern" ]; then
  warn "$name: no archive_pattern in manifest (skipped)"
  exit 0
fi

init_tools_dir
install_tool "$name" "$repo" "$archive_pattern" "${binname:-$name}" "${path_hint:-}"
