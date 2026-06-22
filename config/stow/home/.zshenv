# ~/.zshenv (stow package: home) — the ONLY zsh file that lives in $HOME.
#
# It locates the dotfiles repo from its own real path (resolving the stow
# symlink), points ZDOTDIR at the in-repo zsh config, and hands off. Every other
# zsh startup files (.zshenv/.zprofile/.zshrc) live under
# $ZDOTDIR = $DOTFILES_DIR/config/zsh
# inside the repo, so $HOME stays clean and there are no per-file symlinks.
#
# %x = the file currently being sourced (works even when this is a symlink);
# :A resolves it to the real path; :h:h:h:h strips config/stow/home/.zshenv.
if [[ -z ${DOTFILES_DIR:-} ]]; then
  _dfself=${${(%):-%x}:A}
  [[ -n $_dfself && -d ${_dfself:h:h:h:h}/config/zsh ]] && DOTFILES_DIR=${_dfself:h:h:h:h}
  unset _dfself
fi
: ${DOTFILES_DIR:=$HOME/dotfiles_v2}
export DOTFILES_DIR
export ZDOTDIR="$DOTFILES_DIR/config/zsh"

# zsh only auto-reads $HOME/.zshenv (ZDOTDIR was still unset when it did), so we
# source the real per-user .zshenv from $ZDOTDIR ourselves. The later startup
# files (.zprofile, .zshrc, .zlogin) are picked up from $ZDOTDIR automatically.
[[ -r $ZDOTDIR/.zshenv ]] && source $ZDOTDIR/.zshenv
