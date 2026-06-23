# zellij — terminal multiplexer (attach manually: zj, zellij, or tmux alias).
command -v zellij >/dev/null 2>&1 || return 0

alias tmux='zellij'
alias zj='zellij'
