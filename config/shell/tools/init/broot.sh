# broot — tree navigator. The shell function defines the `br` launcher so you
# can cd into the directory picked in broot.
command -v broot >/dev/null 2>&1 || return 0

# Initialize shell function (deferred in zsh, sync in bash)
if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached_safe broot "broot --print-shell-function zsh"'
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(broot --print-shell-function bash 2>/dev/null)" 2>/dev/null || true
fi

# Fall back to the installed launcher script if the shell function is absent.
_br_launcher="${XDG_CONFIG_HOME:-$HOME/.config}/broot/launcher/bash/br"
[ -r "$_br_launcher" ] && . "$_br_launcher"
unset _br_launcher
