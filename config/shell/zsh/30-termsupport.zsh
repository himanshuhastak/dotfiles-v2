# config/shell/zsh/30-termsupport.zsh — set the terminal / tab title.
# Adapted from oh-my-zsh lib/termsupport.zsh. Shows "user@host: cwd" at the
# prompt and the running command while it executes. Disable with
# DOTFILES_DISABLE="termsupport" or by setting DISABLE_AUTO_TITLE=true.

# Emit an xterm/screen title escape. $1 = tab/title text.
_dotfiles_title() {
  [[ "${DISABLE_AUTO_TITLE:-}" == true ]] && return
  local txt=${(V)1}
  case "$TERM" in
    xterm*|rxvt*|alacritty*|konsole*|tmux*|*-256color) print -Pn "\e]2;${txt}\a" ;;
    screen*)                                            print -Pn "\ek${txt}\e\\" ;;
  esac
}

# At the prompt: user@host: shortened-cwd  (%~ collapses $HOME to ~).
_dotfiles_title_precmd()  { _dotfiles_title "%n@%m: %~"; }
# While a command runs: the command line (first word, trimmed).
_dotfiles_title_preexec() { _dotfiles_title "%n@%m: ${1%% *}"; }

autoload -Uz add-zsh-hook
add-zsh-hook precmd  _dotfiles_title_precmd
add-zsh-hook preexec _dotfiles_title_preexec
