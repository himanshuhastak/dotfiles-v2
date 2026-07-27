# $ZDOTDIR/.zprofile — login shells only (bash handoff: `env -i … zsh -l` by default;
# set DOTFILES_ZSH_LOGIN=0 for non-login handoff — see config/stow/bash/.bashrc).
# Not run for `zsh -c`, non-login subshells, or scripts. Env/PATH are in .zshenv.

# Self-heal stow symlinks once per login (only heal path — no deferred non-login heal).
(( ${+commands[dotfiles]} )) && dotfiles stow --if-needed >/dev/null 2>&1
(( ${+commands[dotfiles]} )) && dotfiles work-stow --if-needed >/dev/null 2>&1
(( ${+commands[dotfiles]} )) && dotfiles ssh-sync --if-needed >/dev/null 2>&1

# X11 — normalize xauth and merge cookies (SSH, LSF/bsub, GDM → ~/.Xauthority).
if [[ -n ${DISPLAY:-} && -r $DOTFILES_DIR/config/shell/lib/x11-forwarding.sh ]]; then
  source "$DOTFILES_DIR/config/shell/lib/x11-forwarding.sh"
  apply_x11_forwarding_fix 2>/dev/null || true
fi

# Personal login setup (cluster modules, login-only exports).
_load_profile login

# Host/user-specific login tweaks (untracked, in $HOME — never the repo).
[[ -r ~/.zprofile.$USER ]] && . ~/.zprofile.$USER
