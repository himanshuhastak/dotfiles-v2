# Login: self-heal $HOME via chezmoi.
(( ${+commands[dotfiles]} )) && dotfiles apply --if-needed >/dev/null 2>&1

if [[ -n ${DISPLAY:-} && -r $DOTFILES_DIR/config/shell/lib/x11-forwarding.sh ]]; then
  source "$DOTFILES_DIR/config/shell/lib/x11-forwarding.sh"
  apply_x11_forwarding_fix 2>/dev/null || true
fi

_load_profile login
[[ -r ~/.zprofile.$USER ]] && . ~/.zprofile.$USER
