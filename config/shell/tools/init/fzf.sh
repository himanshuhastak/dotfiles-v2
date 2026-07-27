# fzf — fuzzy finder. Env + aliases are portable; key-binding hooks are per-shell.
# Modern fzf uses `fzf --zsh` / `fzf --bash` (not `fzf init <shell>`).
command -v fzf >/dev/null 2>&1 || return 0

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 60% --layout=reverse --border --info=inline --color=fg:-1,bg:-1,hl:#f38ba8 --color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8 --color=info:#89b4fa,prompt:#cba6f7,pointer:#f5e2af --color=marker:#94e2d5,spinner:#f9e2af,header:#94e2d5}"

# fd as the default file source (respects .gitignore, much faster than find).
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# bat preview for Ctrl-T file picker (syntax-highlighted, first 500 lines).
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS---preview 'bat --color=always --style=numbers --line-range :500 {}' --preview-window=right:55%:wrap}"
fi

# eza/ls tree preview for Alt-C directory picker.
if command -v eza >/dev/null 2>&1; then
  export FZF_ALT_C_OPTS="${FZF_ALT_C_OPTS---preview 'eza --tree --level=2 --color=always --icons=auto {}'}"
elif command -v ls >/dev/null 2>&1; then
  export FZF_ALT_C_OPTS="${FZF_ALT_C_OPTS---preview 'ls -la {}'}"
fi

if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached_safe fzf "fzf --zsh"'
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(fzf --bash 2>/dev/null)" 2>/dev/null || true
fi
