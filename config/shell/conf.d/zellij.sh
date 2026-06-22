# zellij — terminal multiplexer.
command -v zellij >/dev/null 2>&1 || return 0

alias tmux='zellij'
alias zj='zellij'

# Auto-attach (or start new session) when connecting over SSH without an
# existing multiplexer. Only runs when: inside SSH, zellij is not already
# running, and the terminal supports it (not a dumb terminal).
if [ -n "${SSH_CONNECTION:-}" ] && [ -z "${ZELLIJ:-}" ] && [ "${TERM:-}" != dumb ]; then
  # Attach to existing session if one exists; otherwise start fresh.
  if zellij list-sessions 2>/dev/null | grep -q .; then
    exec zellij attach
  else
    exec zellij
  fi
fi
