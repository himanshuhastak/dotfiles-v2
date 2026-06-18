# config/shell/zsh/45-functions.zsh — lazily autoloaded zsh functions.
# Each file in config/shell/functions/ defines ONE function whose name == the
# ONE function whose name == the filename. They are autoloaded: a file is only
# parsed the first time its function is called, so the dir can grow without
# adding any startup cost. (Portable bash+zsh helpers live in core/10-functions.sh.)
local _fns
for _fns in "$DOTFILES_DIR/config/shell/functions"; do
  [[ -d "$_fns" ]] || continue
  fpath=("$_fns" $fpath)
  autoload -Uz "$_fns"/*(N:t)
done
unset _fns
