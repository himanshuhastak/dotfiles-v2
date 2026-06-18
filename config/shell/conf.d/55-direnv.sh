# direnv — per-directory environments (.envrc).
command -v direnv >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached direnv "direnv hook zsh"'
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(direnv hook bash)"
fi
