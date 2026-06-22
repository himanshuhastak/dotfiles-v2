# $ZDOTDIR/.zprofile — login shells only (bash handoff uses `env -i … zsh -l`).
# Not run for `zsh -c`, non-login subshells, or scripts. Env/PATH are in .zshenv.

# Self-heal stow symlinks once per login (NFS-shared home safety net).
(( ${+commands[dotfiles]} )) && dotfiles stow --if-needed >/dev/null 2>&1

# Personal login setup (cluster modules, login-only exports).
_load_profile login

# Host/user-specific login tweaks (untracked, in $HOME — never the repo).
[[ -r ~/.zprofile.$USER ]] && . ~/.zprofile.$USER
