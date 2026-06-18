# starship — cross-shell prompt. Loaded late so it owns the final prompt setup.
# NOT deferred (unlike the other tool hooks): it draws the prompt, so it must
# initialise synchronously before the first prompt is shown.
command -v starship >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then
  _eval_cached starship "starship init zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(starship init bash)"
fi
