# bat — cat clone with syntax highlighting.
command -v bat >/dev/null 2>&1 || return 0

alias cat='bat --paging=never'
alias less='bat'

# Use bat as man pager (col strips bold/underline, bat re-adds syntax highlighting).
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT='-c' # prevent groff from emitting escape sequences

# Default theme (Catppuccin Mocha — pairs with the fzf colour scheme).
export BAT_THEME="${BAT_THEME:-Catppuccin Mocha}"
