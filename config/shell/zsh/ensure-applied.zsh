# Non-login shells: deferred chezmoi self-heal (login runs apply in .zprofile).
[[ -o login ]] && return 0
((${+commands[dotfiles]})) && _defer 'dotfiles apply --if-needed >/dev/null 2>&1'
