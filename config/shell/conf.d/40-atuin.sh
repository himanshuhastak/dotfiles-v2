# atuin — shell history database. Loads after fzf so atuin owns Ctrl-R;
# --disable-up-arrow leaves the up key for zsh history-substring-search.
command -v atuin >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached atuin "atuin init zsh --disable-up-arrow"'
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(atuin init bash --disable-up-arrow)"
fi
