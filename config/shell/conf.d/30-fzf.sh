# fzf — fuzzy finder. Env + aliases are portable; key-binding hooks are per-shell.
command -v fzf >/dev/null 2>&1 || return 0

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 60% --layout=reverse --border --info=inline \
--color=fg:-1,bg:-1,hl:#f38ba8 \
--color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8 \
--color=info:#89b4fa,prompt:#cba6f7,pointer:#f5e2af \
--color=marker:#94e2d5,spinner:#f9e2af,header:#94e2d5}"
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached fzf "fzf --zsh"'
elif [ -n "${BASH_VERSION:-}" ]; then
  fzf --bash >/dev/null 2>&1 && eval "$(fzf --bash)"
fi
