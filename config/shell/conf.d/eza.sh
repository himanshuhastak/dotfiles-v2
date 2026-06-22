# eza — modern ls replacement.
command -v eza >/dev/null 2>&1 || return 0

alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -lah --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'
alias tree='eza --tree --icons=auto'

# Consistent Catppuccin-compatible colour palette for eza entries.
# Colour codes: di=dir, ln=symlink, ex=exec, fi=file, *.ext=extension.
export EZA_COLORS="${EZA_COLORS:-di=34:ln=36:ex=32:fi=0:*.md=35:*.toml=33:*.sh=32:*.zsh=32}"
export EZA_STRICT=0   # don't error on unknown flags in older eza builds
