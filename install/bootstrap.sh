#!/usr/bin/env bash
# End-to-end dotfiles bootstrap.
#   bootstrap.sh [--skip-fonts] [--skip-tools] [--fetch-theme] [--sequential-tools]
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
    --skip-fonts)        SKIP_FONTS=1 ;;
    --skip-tools)        SKIP_TOOLS=1 ;;
    --fetch-theme)       THEME_ARGS+=(--force) ;;
    --sequential-tools)  TOOL_ARGS+=(--sequential) ;;
    --parallel-tools)    TOOL_ARGS+=(--parallel) ;;
    --with-optional-tools) TOOL_ARGS+=(--with-optional) ;;
    *) warn "unknown arg: $arg" ;;
  esac
done

run() {
  printf '\n\033[1;35m######\033[0m %s\n' "$1"
  bash "$STEPS/$1" "${@:2}"
}

run install-stow.sh
bash "$INSTALL/bin/fix-executable-bits.sh" >/dev/null 2>&1 || true
run fetch-themes.sh "${THEME_ARGS[@]}"
[ "$SKIP_TOOLS" -eq 0 ] && run install-tools.sh "${TOOL_ARGS[@]}" || skip "tools (--skip-tools)"
run install-zellij-plugins.sh
run stow-dotfiles.sh
run install-sheldon-plugins.sh
[ "$SKIP_FONTS" -eq 0 ] && run install-fonts.sh || skip "fonts (--skip-fonts)"
run fix-ssh.sh
bash "$INSTALL/steps/migrate-ssh-profile.sh" 2>/dev/null || true
run fix-ssh-config.sh
run profile-git-local.sh
run fix-default-shell.sh
run fix-x11-forwarding.sh
run fix-task-hooks.sh

# Byte-compile the zsh framework for faster startup (best-effort, zsh only).
"$DOTFILES/bin/dotfiles" compile >/dev/null 2>&1 || true
# Regenerate the man page from the CLI help so `man dotfiles` is current.
"$DOTFILES/bin/dotfiles" doc man >/dev/null 2>&1 || true

init_tools_dir
echo
ok "Setup complete."
echo "  tools:   $BIN"
echo "  stow:    $STOW"
echo "  theme:   catppuccin mocha (starship, zellij, bat, delta, lazygit, fzf)"
have starship && echo "  prompt:  starship"
have sheldon  && echo "  zsh:     sheldon plugins -> $DOTFILES/var/vendor"
have zellij   && echo "  mux:     zellij + plugins -> $DOTFILES/var/vendor/zellij-plugins"
if [ -d "$DOTFILES_NERDFONTS_DIR" ]; then
  fonts_installed=0
  for f in "$DOTFILES_NERDFONTS_DIR"/*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.otf|*.ttf|*.OTF|*.TTF)
        [ -f "$FONT_DIR/$(basename "$f")" ] && fonts_installed=$((fonts_installed + 1))
        ;;
    esac
  done
  [ "$fonts_installed" -gt 0 ] && \
    echo "  fonts:   $fonts_installed bundled Nerd Font(s) in $FONT_DIR (default: $DOTFILES_FONT_LABEL)"
fi
echo
if [ -x "$BIN/zsh" ]; then
  echo "Open a fresh shell:  exec $BIN/zsh -l   (or: dotfiles reload)"
else
  echo "Open a fresh shell:  exec zsh   (run install again if zsh build failed)"
fi
