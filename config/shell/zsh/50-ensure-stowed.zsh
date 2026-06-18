# config/shell/zsh/50-ensure-stowed.zsh — self-heal stow symlinks (non-login).
#
# Login shells run `dotfiles stow --if-needed` synchronously in $ZDOTDIR/.zprofile.
# Non-login interactive shells (e.g. `zsh` from an existing session) get the same
# safety net deferred so it never delays the prompt.
[[ -o login ]] && return 0
(( ${+commands[dotfiles]} )) && _defer 'dotfiles stow --if-needed >/dev/null 2>&1'
