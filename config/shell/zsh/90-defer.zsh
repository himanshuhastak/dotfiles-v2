# config/shell/zsh/90-defer.zsh — staged/async startup via zsh-defer (romkatv).
#
# Sourcing zsh-defer here (just before plugins + the conf.d tool hooks) makes
# the `zsh-defer` function available so heavy `eval "$(tool init)"` snippets run
# AFTER the first prompt is drawn → the shell is usable instantly and finishes
# wiring up (Ctrl-R history, z, direnv, …) a few ms later.
#
# zsh-defer is downloaded into var/vendor by install (var = the only generated
# tree). If it is missing or this module is disabled, _defer stays synchronous
# (the default defined in loader.sh), so nothing breaks.

_zd="${SHELDON_DATA_DIR:-$DOTFILES_DIR/var/vendor}/zsh-defer/zsh-defer.plugin.zsh"
[[ -r "$_zd" ]] && source "$_zd"
unset _zd

if (( ${+functions[zsh-defer]} )); then
  # Run the code string after the first prompt. zsh-defer's default options
  # (12dmsr) silence output and refresh prompt/suggestions/highlight afterwards.
  _defer() { zsh-defer -c "$1"; }
fi
