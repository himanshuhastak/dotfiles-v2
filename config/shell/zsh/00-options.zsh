# config/shell/zsh/00-options.zsh — zsh shell options + keymap selection.

setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP

# Treat '/' as a word boundary so backward-kill-word stops at path components
# (default WORDCHARS includes '/', so Ctrl+Backspace would erase a whole path).
WORDCHARS=${WORDCHARS//\/}

# Emacs keybindings + sane backspace. Chosen early so later tool hooks
# (fzf/atuin) bind into the emacs keymap rather than getting reset afterwards.
bindkey -e
bindkey '^?' backward-delete-char
