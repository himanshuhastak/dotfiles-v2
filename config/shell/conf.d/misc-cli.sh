# Small drop-in replacements + shortcuts, each guarded by availability.
# Grouped because they are one-liners with no per-tool config beyond an alias.

# command -v choose   >/dev/null 2>&1 && alias cut='choose'
# command -v sd       >/dev/null 2>&1 && alias sed='sd'
# command -v dust     >/dev/null 2>&1 && alias du='dust'
command -v duf      >/dev/null 2>&1 && alias df='duf'
command -v gdu      >/dev/null 2>&1 && alias ncdu='gdu'
command -v procs    >/dev/null 2>&1 && alias ps='procs'
command -v oc-rsync >/dev/null 2>&1 && alias rsync='oc-rsync'
command -v lazygit  >/dev/null 2>&1 && alias lg='lazygit'
command -v just     >/dev/null 2>&1 && alias j='just'
command -v zellij   >/dev/null 2>&1 && alias tmux='zellij'
command -v tldr     >/dev/null 2>&1 && alias help='tldr'
command -v task     >/dev/null 2>&1 && alias t='task'
command -v taskwarrior-tui >/dev/null 2>&1 && alias tt='taskwarrior-tui'
command -v timew    >/dev/null 2>&1 && alias tw='timew'
