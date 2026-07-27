# config/shell/tools/init.sh — ordered tool init hooks (before tools/*.sh env/aliases).
# Loaded explicitly from config/zsh/.zshrc after compinit.
for _init in fzf atuin zoxide direnv broot starship; do
  _load_file "$DOTFILES_DIR/config/shell/tools/init/${_init}.sh"
done
unset _init
