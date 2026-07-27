# $ZDOTDIR/.zshrc — interactive zsh.

[[ -n "${DOTFILES_PROFILE:-}" ]] && zmodload zsh/zprof

source_r "$DOTFILES_DIR/config/shell/functions.sh"
source_r "$DOTFILES_DIR/config/shell/aliases.sh"

[[ -o interactive ]] || return

_load_profile aliases

# zsh-only modules — explicit order (no NN- filename prefixes).
for _z in options zmodload colors directories history completion termsupport hashdirs \
  functions ensure-applied defer plugins session-state event-hooks keybindings; do
  source_r "$DOTFILES_DIR/config/shell/zsh/${_z}.zsh"
done
unset _z

# Tool init hooks (ordered) then per-tool env/aliases.
_load_file "$DOTFILES_DIR/config/shell/tools/init.sh"
for _t in "$DOTFILES_DIR/config/shell/tools"/*.sh(N); do
  [[ "${_t##*/}" == init.sh ]] && continue
  _load_file "$_t"
done
unset _t

_load_profile tools
_load_profile company

[[ -r ~/.zshrc.$USER ]] && . ~/.zshrc.$USER
[[ -n "${DOTFILES_PROFILE:-}" ]] && zprof
