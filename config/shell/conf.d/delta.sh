# delta — syntax-highlighting pager for git diffs.
command -v delta >/dev/null 2>&1 || return 0
export GIT_PAGER=delta
