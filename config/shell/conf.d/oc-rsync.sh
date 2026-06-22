# oc-rsync — Rust rsync (wire-compatible with rsync 3.4.1).
command -v oc-rsync >/dev/null 2>&1 || return 0
alias rsync='oc-rsync'
