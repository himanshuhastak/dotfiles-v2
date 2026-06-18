# config/shell/zsh/40-hashdirs.zsh — named directory hashes (`hash -d`).
# Create short, tab-completable names for the dirs you visit most:
#   cd ~dot        # the repo
#   cd ~dotcfg     # config/
#   ls ~vendor     # cloned zsh plugins
# They also shorten paths in the prompt (~dot/config instead of the full path).
hash -d dot="$DOTFILES_DIR"
hash -d dotcfg="$DOTFILES_DIR/config"
hash -d tools="${TOOLS_DIR:-$DOTFILES_DIR/var/tools}"
hash -d vendor="${SHELDON_DATA_DIR:-$DOTFILES_DIR/var/vendor}"
[[ -d "${XDG_CONFIG_HOME:-$HOME/.config}" ]] && hash -d cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
