# delta — syntax-highlighting pager for git diffs.
command -v delta >/dev/null 2>&1 || return 0

export GIT_PAGER=delta

# LESS flags needed by delta: R=raw ANSI, X=no init/deinit, F=quit-if-one-screen.
export LESS="${LESS:--RXF}"
export DELTA_PAGER="${DELTA_PAGER:-less -+FX}"

# Paging is also set in ~/.gitconfig [pager] diff/show/log/reflog = delta.
# Do not set GIT_EXTERNAL_DIFF: delta is a pager (stdin), not a git external-diff
# driver (file paths + object ids). That misconfiguration breaks `git diff`.
