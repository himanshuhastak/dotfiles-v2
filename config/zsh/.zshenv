# $ZDOTDIR/.zshenv — every zsh invocation (login, interactive, scripts).
# DOTFILES_DIR is set by chezmoi-managed ~/.zshenv before this file runs.
: "${DOTFILES_DIR:?DOTFILES_DIR not set — run: dotfiles apply}"

# BASH leaks when zsh is spawned from bash.
[[ -n ${BASH+x} ]] && unset BASH

# Prefer vendored zsh when installed (re-exec once).
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

[ -r "$DOTFILES_DIR/config/shell/loader.sh" ] && . "$DOTFILES_DIR/config/shell/loader.sh"
[ -r "$DOTFILES_DIR/config/shell/env.sh" ]     && . "$DOTFILES_DIR/config/shell/env.sh"
