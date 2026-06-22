# rg — ripgrep (faster grep replacement).
command -v rg >/dev/null 2>&1 || return 0
alias grep='rg --smart-case'
alias rgi='rg -i'
