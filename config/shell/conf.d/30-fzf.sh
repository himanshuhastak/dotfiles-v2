# fzf — fuzzy finder. Env + aliases are portable; key-binding hooks are per-shell.
# Custom env setup + deferred init via _init_tool_hook.
command -v fzf >/dev/null 2>&1 || return 0

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 60% --layout=reverse --border --info=inline \
--color=fg:-1,bg:-1,hl:#f38ba8 \
--color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8 \
--color=info:#89b4fa,prompt:#cba6f7,pointer:#f5e2af \
--color=marker:#94e2d5,spinner:#f9e2af,header:#94e2d5}"

# Set up FZF_DEFAULT_COMMAND if fd is available
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Initialize shell integration (deferred in zsh, sync in bash)
_init_tool_hook fzf --defer
