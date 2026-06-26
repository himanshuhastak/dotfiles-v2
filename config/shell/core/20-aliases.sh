# config/shell/core/20-aliases.sh — base aliases (portable: bash + zsh).
# Tool-specific overrides (eza/bat/rg/...) live in ../conf.d/<tool>.sh and load
# AFTER this file, so an installed modern replacement transparently wins.

# Directory traversal (oh-my-zsh convention; portable).
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias ls='ls --color'
alias l='ls'
alias ll='ls -al --color'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias mkdir='mkdir -pv'
alias rm='rm -iv'
alias mv='mv -iv'
alias h='history'
alias r='readlink -f'
alias less='less -N -i -M -FsRXc -w'
alias ssh='ssh -Y'
alias mkm='mkcd "$(date_ist +%Y-%m)"'
alias mkd='mkcd "$(date_ist +%Y-%m-%d)"'
