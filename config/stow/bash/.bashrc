# ~/.bashrc — interactive bash hands off to login zsh (see bash-zsh-handoff.sh).
# For a full interactive bash instead: . "$DOTFILES_DIR/config/shell/shrc"

[[ -f /etc/bashrc ]] && . /etc/bashrc
case $- in *i*) ;; *) return ;; esac

_dfself="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
_handoff="$(cd "$(dirname "$_dfself")/../../../config/shell/lib" 2>/dev/null && pwd)/bash-zsh-handoff.sh"

if [[ -r "$_handoff" ]]; then
  # shellcheck disable=SC1090
  . "$_handoff"
  dotfiles_bash_zsh_handoff "$_dfself"
fi

printf 'dotfiles: bash→zsh handoff missing at %s\n' "${_handoff:-unknown}" >&2
unset _dfself _handoff
return 1
