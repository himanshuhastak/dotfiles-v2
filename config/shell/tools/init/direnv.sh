# direnv — per-directory environments (.envrc).
# direnv hook <shell> outputs a small eval snippet; cache it like other tools.
command -v direnv >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached_safe direnv "direnv hook zsh"'
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(direnv hook bash)" 2>/dev/null || true
fi
