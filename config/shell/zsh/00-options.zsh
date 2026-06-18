# config/shell/zsh/00-options.zsh — zsh shell options + keymap selection.

setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP

# Emacs keybindings + sane backspace. Chosen early so later tool hooks
# (fzf/atuin) bind into the emacs keymap rather than getting reset afterwards.
bindkey -e
bindkey '^?' backward-delete-char
