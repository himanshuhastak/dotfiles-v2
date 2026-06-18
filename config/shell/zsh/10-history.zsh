# config/shell/zsh/10-history.zsh — history config (file kept under XDG state).
# atuin (conf.d/40-atuin.sh) provides interactive search over its own DB and
# imports from this file; this stays as zsh's in-session history + backup.

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || command mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000

# Standard, conservative history behaviour (oh-my-zsh lib/history.zsh):
setopt EXTENDED_HISTORY        # record timestamp + duration per entry
setopt INC_APPEND_HISTORY      # write as commands run, not just at exit
setopt SHARE_HISTORY           # share across concurrent sessions
setopt HIST_IGNORE_ALL_DUPS    # drop older duplicates of a command
setopt HIST_IGNORE_SPACE       # skip commands starting with a space
setopt HIST_FIND_NO_DUPS       # don't show dupes when searching
setopt HIST_REDUCE_BLANKS      # trim superfluous blanks before saving
setopt HIST_VERIFY             # expand !! etc. onto the line before running
setopt HIST_EXPIRE_DUPS_FIRST # trim duplicates first when the list fills (prezto)
setopt HIST_SAVE_NO_DUPS      # never write a duplicate event to the file (prezto)
setopt BANG_HIST              # treat '!' specially for history expansion (prezto)
