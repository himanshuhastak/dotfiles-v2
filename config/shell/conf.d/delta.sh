# delta — syntax-highlighting pager for git diffs.
command -v delta >/dev/null 2>&1 || return 0

export GIT_PAGER=delta

# LESS flags needed by delta: R=raw ANSI, X=no init/deinit, F=quit-if-one-screen.
export LESS="${LESS:--RXF}"
export DELTA_PAGER="${DELTA_PAGER:-less -+FX}"

# Let delta also handle plain `diff` output when called via git aliases.
export GIT_EXTERNAL_DIFF=delta
