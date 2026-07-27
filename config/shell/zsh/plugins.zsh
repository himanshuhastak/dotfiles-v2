# config/shell/zsh/95-plugins.zsh — plugins via sheldon (https://sheldon.cli.rs).
# Loads after compinit (20) so fzf-tab can wrap the completion system; the
# plugins.toml keeps zsh-syntax-highlighting last. Clones live in
# <repo>/var/vendor (gitignored); plugin list in ~/.config/sheldon.
# SHELDON_DATA_DIR is exported by core/00-env.sh (with legacy fallback).
export SHELDON_DATA_DIR="${SHELDON_DATA_DIR:-$DOTFILES_DIR/var/vendor}"
# Not cached: `sheldon source` output depends on plugins.toml/lock, not the
# sheldon binary, so a stale cache would silently ignore plugin changes.
command -v sheldon >/dev/null 2>&1 && eval "$(sheldon source)"
