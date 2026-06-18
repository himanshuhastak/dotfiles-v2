# config/shell/zsh/99-keybindings.zsh — keymaps + key bindings.
# Loaded last (after 95-plugins) so widgets defined by plugins
# (history-substring-search, etc.) already exist when we bind them.
#
# Design (synthesised from zsh4humans, grml, oh-my-zsh, zimfw):
#   1. Application mode: turn keypad transmit on while editing so $terminfo
#      key values are valid. Installed via add-zle-hook-widget so we coexist
#      with plugin-owned line-init/finish hooks instead of replacing them.
#   2. Normalisation layer (z4h-style): fold the many terminal-specific escape
#      variants a key can emit (application-mode "^[O...", rxvt/screen/linux
#      "^[[1~"/"^[[7~"/"^[[4~"/"^[[8~", ...) into one canonical sequence with
#      `bindkey -s`. Then we bind each widget to just the canonical form.
#   3. Bind widgets across emacs/viins/vicmd so movement keys work in any mode.

# --- 1. application mode ------------------------------------------------------
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  function _dot_zle_smkx() { echoti smkx; }
  function _dot_zle_rmkx() { echoti rmkx; }
  autoload -Uz add-zle-hook-widget 2>/dev/null
  if (( ${+functions[add-zle-hook-widget]} )); then
    add-zle-hook-widget line-init   _dot_zle_smkx
    add-zle-hook-widget line-finish _dot_zle_rmkx
  else
    zle -N zle-line-init   _dot_zle_smkx
    zle -N zle-line-finish _dot_zle_rmkx
  fi
fi

# --- 2. normalisation: variant sequence  ->  canonical sequence ---------------
# `bindkey -s` re-feeds the replacement into ZLE, so a single canonical bind
# below covers every terminal that emits any of these variants.
bindkey -s '^[OA' '^[[A'      # Up    (application mode)
bindkey -s '^[OB' '^[[B'      # Down
bindkey -s '^[OC' '^[[C'      # Right
bindkey -s '^[OD' '^[[D'      # Left
bindkey -s '^[OH' '^[[H'      # Home  (application mode)
bindkey -s '^[OF' '^[[F'      # End
bindkey -s '^[[1~' '^[[H'     # Home  (linux console / vt)
bindkey -s '^[[7~' '^[[H'     # Home  (rxvt / screen)
bindkey -s '^[[4~' '^[[F'     # End   (linux console / vt)
bindkey -s '^[[8~' '^[[F'     # End   (rxvt / screen)
bindkey -s '^[Od' '^[[1;5D'   # Ctrl-Left  (application mode)
bindkey -s '^[Oc' '^[[1;5C'   # Ctrl-Right (application mode)
bindkey -s '^[^[[D' '^[[1;3D' # Alt-Left  (rxvt)
bindkey -s '^[^[[C' '^[[1;3C' # Alt-Right (rxvt)

# --- 3. canonical bindings ----------------------------------------------------
# Bind in emacs + viins + vicmd so navigation works regardless of keymap.
_dotbind() {
  local seq=$1 widget=$2
  bindkey -M emacs "$seq" "$widget"
  bindkey -M viins "$seq" "$widget"
  bindkey -M vicmd "$seq" "$widget"
}

_dotbind '^[[H'    beginning-of-line       # Home
_dotbind '^[[F'    end-of-line             # End
_dotbind '^[[3~'   delete-char             # Delete
_dotbind '^[[3;5~' kill-word               # Ctrl-Delete
_dotbind '^[[3;3~' kill-word               # Alt-Delete
_dotbind '^[[1;5D' backward-word           # Ctrl-Left
_dotbind '^[[1;5C' forward-word            # Ctrl-Right
_dotbind '^[[1;3D' backward-word           # Alt-Left
_dotbind '^[[1;3C' forward-word            # Alt-Right
unfunction _dotbind

# Insert / PageUp / PageDown / Shift-Tab from terminfo (same in both modes).
[[ -n ${terminfo[kich1]} ]] && bindkey "${terminfo[kich1]}" overwrite-mode
[[ -n ${terminfo[kpp]}   ]] && bindkey "${terminfo[kpp]}"   up-line-or-history
[[ -n ${terminfo[knp]}   ]] && bindkey "${terminfo[knp]}"   down-line-or-history
[[ -n ${terminfo[kcbt]}  ]] && bindkey "${terminfo[kcbt]}"  reverse-menu-complete

# History expansion on space; insert last arg of previous command (Alt-.).
bindkey ' ' magic-space
bindkey '^[.' insert-last-word
bindkey '^[_' insert-last-word

# --- history-substring-search (plugin widgets, loaded at 95) ------------------
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# --- edit-command-line: open the current command in $EDITOR -------------------
#   emacs keymap: ^X^E and Alt-e   |   vicmd: v
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
bindkey '^[e'  edit-command-line
bindkey -M vicmd 'v' edit-command-line
