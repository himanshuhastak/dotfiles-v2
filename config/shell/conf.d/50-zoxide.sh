# zoxide — frecency-based directory jumper (provides `z`, used by the cd wrapper).
command -v zoxide >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached zoxide "zoxide init zsh"'
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(zoxide init bash)"
fi
