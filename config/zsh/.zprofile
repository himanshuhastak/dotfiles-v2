# $ZDOTDIR/.zprofile — login shells only (bash handoff uses `env -i … zsh -l`).
# Not run for `zsh -c`, non-login subshells, or scripts. Env/PATH are in .zshenv.

# Self-heal stow symlinks once per login (NFS-shared home safety net).
(( ${+commands[dotfiles]} )) && dotfiles stow --if-needed >/dev/null 2>&1
(( ${+commands[dotfiles]} )) && dotfiles work-stow --if-needed >/dev/null 2>&1

# SSH X11 forwarding — merge xauth cookies when DISPLAY is forwarded.
if [[ -n ${DISPLAY:-} && -r $DOTFILES_DIR/config/shell/lib/x11-forwarding.sh ]]; then
  source "$DOTFILES_DIR/config/shell/lib/x11-forwarding.sh"
  apply_x11_forwarding_fix 2>/dev/null || true
fi

# Personal login setup (cluster modules, login-only exports).
_load_profile login

# Host/user-specific login tweaks (untracked, in $HOME — never the repo).
[[ -r ~/.zprofile.$USER ]] && . ~/.zprofile.$USER
