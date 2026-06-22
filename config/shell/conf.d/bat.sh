# bat — cat clone with syntax highlighting.
command -v bat >/dev/null 2>&1 || return 0
alias cat='bat --paging=never'
alias less='bat'
