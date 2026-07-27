# config/shell/zsh/04-colors.zsh — base colors.
# Centralises LS_COLORS (consumed by `ls` AND by the completion menu's
# list-colors in 20-completion) and loads zsh's named-color arrays ($fg/$bg/$reset_color)
# for use in functions and scripts. Runs before 20-completion so colors exist there.
autoload -Uz colors && colors 2>/dev/null

if [[ -z "${LS_COLORS:-}" ]]; then
  if command -v dircolors >/dev/null 2>&1; then
    _dc="${XDG_CONFIG_HOME:-$HOME/.config}/dircolors"
    if [[ -r "$_dc" ]]; then eval "$(dircolors -b "$_dc")"; else eval "$(dircolors -b)"; fi
    unset _dc
  else
    # Minimal sensible fallback when GNU dircolors isn't available.
    export LS_COLORS='di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34'
  fi
fi
