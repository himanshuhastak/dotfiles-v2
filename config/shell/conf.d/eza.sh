# eza — modern ls replacement.
command -v eza >/dev/null 2>&1 || return 0
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -lah --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'
alias tree='eza --tree --icons=auto'
