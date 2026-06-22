# rg — ripgrep (faster grep replacement).
command -v rg >/dev/null 2>&1 || return 0

alias grep='rg --smart-case'
alias rgi='rg -i'

# Point ripgrep at a user config file (~/.config/ripgrep/ripgreprc) so flags
# like --hidden, --follow, --glob can be set without typing them every time.
export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/ripgrep/ripgreprc}"
