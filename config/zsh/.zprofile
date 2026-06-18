# $ZDOTDIR/.zprofile — login shells only (bash handoff uses `env -i … zsh -l`).
# Not run for `zsh -c`, non-login subshells, or scripts. Env/PATH are in .zshenv.

# Self-heal stow symlinks once per login (NFS-shared home safety net).
(( ${+commands[dotfiles]} )) && dotfiles stow --if-needed >/dev/null 2>&1

# Host/user login tweaks (untracked, in $HOME — never the repo).
[[ -r ~/.zprofile.$USER ]] && . ~/.zprofile.$USER
_load_profile login
