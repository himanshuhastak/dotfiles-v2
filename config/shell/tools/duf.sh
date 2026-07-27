# duf — modern df replacement.
command -v duf >/dev/null 2>&1 || return 0
alias df='duf'
