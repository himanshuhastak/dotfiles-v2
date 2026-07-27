#!/usr/bin/env bash
# install/bootstrap.sh — tools, plugins, chezmoi apply.
set -uo pipefail

INSTALL="$(cd "$(dirname "$0")" && pwd)"
STEPS="$INSTALL/steps"
source "$INSTALL/common.sh"

SKIP_FONTS=0
SKIP_TOOLS=0
THEME_ARGS=()
TOOL_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --skip-fonts) SKIP_FONTS=1 ;;
    --skip-tools) SKIP_TOOLS=1 ;;
    --fetch-theme) THEME_ARGS+=(--force) ;;
    --sequential-tools) TOOL_ARGS+=(--sequential) ;;
    --with-optional-tools) TOOL_ARGS+=(--with-optional) ;;
    *) warn "unknown arg: $arg" ;;
  esac
done

run() {
  printf '\n\033[1;35m######\033[0m %s\n' "$1"
  bash "$STEPS/$1" "${@:2}"
}

run host-setup.sh
run fetch-themes.sh "${THEME_ARGS[@]}"
[ "$SKIP_TOOLS" -eq 0 ] && run install-tools.sh "${TOOL_ARGS[@]}" || skip "tools"
run install-zellij-plugins.sh
run install-sheldon-plugins.sh
[ "$SKIP_FONTS" -eq 0 ] && run install-fonts.sh || skip "fonts"

init_tools_dir
"$DOTFILES/bin/dotfiles" apply
"$DOTFILES/bin/dotfiles" compile >/dev/null 2>&1 || true
"$DOTFILES/bin/dotfiles" doc man >/dev/null 2>&1 || true

echo
ok "Setup complete."
echo "  repo:    $DOTFILES"
echo "  aqua:    ${AQUA_ROOT_DIR:-$DOTFILES/var/tools/aqua}"
echo "  tools:   $BIN (legacy) + aqua bin on PATH"
echo "  apply:   dotfiles apply   (chezmoi → \$HOME)"
echo "  shell:   exec zsh -l  (or: dotfiles reload)"
