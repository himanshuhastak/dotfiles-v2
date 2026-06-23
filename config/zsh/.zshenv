# $ZDOTDIR/.zshenv — sourced for EVERY zsh invocation (login, interactive,
# scripts) via the ~/.zshenv bootstrap, which sets DOTFILES_DIR + ZDOTDIR and
# then sources this file. Env/PATH only; keep minimal and SILENT so that
# non-interactive zsh (`zsh -c`, `#!/usr/bin/zsh` scripts, scp/rsync) stays clean.
: "${DOTFILES_DIR:=$HOME/dotfiles_v2}"

# Prefer self-built zsh over /bin/zsh — re-exec once (same idea as bash .bashrc).
if [[ -z "${DOTFILES_NO_ZSH_REEXEC:-}" && -z "${DOTFILES_ZSH_REEXECED:-}" ]]; then
  [[ -r "$DOTFILES_DIR/config/shell/lib/dotfiles-zsh.sh" ]] && \
    source "$DOTFILES_DIR/config/shell/lib/dotfiles-zsh.sh"

  _df_zsh=""
  if typeset -f dotfiles_self_zsh_bin >/dev/null 2>&1; then
    _df_zsh="$(dotfiles_self_zsh_bin)" || true
  elif [[ -x "$DOTFILES_DIR/var/tools/bin/zsh" ]]; then
    _df_zsh="$DOTFILES_DIR/var/tools/bin/zsh"
  fi

  if [[ -n "$_df_zsh" ]]; then
    _df_cur=""
    if typeset -f dotfiles_current_zsh_bin >/dev/null 2>&1; then
      _df_cur="$(dotfiles_current_zsh_bin)" || true
    else
      _df_cur="${ZSH_ARGZERO:-}"
    fi
    [[ -n "$_df_cur" ]] && _df_cur="${_df_cur:A}"
    if [[ -z "$_df_cur" || "$_df_cur" != "${_df_zsh:A}" ]]; then
      export SHELL="$_df_zsh"
      if [[ -o interactive || -o login ]]; then
        export DOTFILES_ZSH_REEXECED=1
        exec -l -- "$_df_zsh"
      fi
    else
      export SHELL="$_df_zsh"
    fi
  fi
  unset _df_zsh _df_cur
fi

[ -r "$DOTFILES_DIR/config/shell/loader.sh" ]      && . "$DOTFILES_DIR/config/shell/loader.sh"
[ -r "$DOTFILES_DIR/config/shell/core/00-env.sh" ] && . "$DOTFILES_DIR/config/shell/core/00-env.sh"
