# $ZDOTDIR/.zshenv — sourced for EVERY zsh invocation (login, interactive,
# scripts) via the ~/.zshenv bootstrap, which sets DOTFILES_DIR + ZDOTDIR and
# then sources this file. Env/PATH only; keep minimal and SILENT so that
# non-interactive zsh (`zsh -c`, `#!/usr/bin/zsh` scripts, scp/rsync) stays clean.
: "${DOTFILES_DIR:=$HOME/dotfiles_v2}"
[ -r "$DOTFILES_DIR/config/shell/loader.sh" ]      && . "$DOTFILES_DIR/config/shell/loader.sh"
[ -r "$DOTFILES_DIR/config/shell/core/00-env.sh" ] && . "$DOTFILES_DIR/config/shell/core/00-env.sh"
