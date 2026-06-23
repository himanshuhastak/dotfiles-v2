# rg — ripgrep (faster grep replacement).
command -v rg >/dev/null 2>&1 || return 0

alias grep='rg --smart-case'
alias rgi='rg -i'

# Point ripgrep at ~/.config/ripgrep/ripgreprc when stowed (avoid errors if missing).
_rg_cfg="${RIPGREP_CONFIG_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/ripgrep/ripgreprc}"
if [ -r "$_rg_cfg" ]; then
  export RIPGREP_CONFIG_PATH="$_rg_cfg"
fi
unset _rg_cfg
