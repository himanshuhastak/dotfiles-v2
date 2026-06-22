# fd — friendlier find.
command -v fd >/dev/null 2>&1 || return 0
alias find='fd'
alias fdh='fd --hidden --no-ignore'
