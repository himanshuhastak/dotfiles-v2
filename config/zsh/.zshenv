# $ZDOTDIR/.zshenv — sourced for EVERY zsh invocation (login, interactive,
# scripts) via the ~/.zshenv bootstrap, which sets DOTFILES_DIR + ZDOTDIR and
# then sources this file. Env/PATH only; keep minimal and SILENT so that
# non-interactive zsh (`zsh -c`, `#!/usr/bin/zsh` scripts, scp/rsync) stays clean.
: "${DOTFILES_DIR:=$HOME/dotfiles_v2}"

# Prefer self-built zsh over /bin/zsh — re-exec once (same idea as bash .bashrc).
if [[ -z "${DOTFILES_NO_ZSH_REEXEC:-}" ]]; then
  _df_zsh="$DOTFILES_DIR/var/tools/bin/zsh"
  if [[ -x "$_df_zsh" ]]; then
    _df_cur="${ZSH_ARGZERO:-}"
    [[ -n "$_df_cur" ]] && _df_cur="${_df_cur:A}"
    if [[ "$_df_cur" != "${_df_zsh:A}" ]]; then
      export SHELL="$_df_zsh"
      [[ -o interactive || -o login ]] && exec -l -- "$_df_zsh"
    else
      export SHELL="$_df_zsh"
    fi
  fi
  unset _df_zsh _df_cur
fi

[ -r "$DOTFILES_DIR/config/shell/loader.sh" ]      && . "$DOTFILES_DIR/config/shell/loader.sh"
[ -r "$DOTFILES_DIR/config/shell/core/00-env.sh" ] && . "$DOTFILES_DIR/config/shell/core/00-env.sh"
