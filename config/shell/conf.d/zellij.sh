# zellij — terminal multiplexer.
command -v zellij >/dev/null 2>&1 || return 0

alias tmux='zellij'
alias zj='zellij'

# Auto-attach (or start new session) when connecting over SSH without an
# existing multiplexer. Only runs when: inside SSH, zellij is not already
# running, and the terminal supports it (not a dumb terminal).
if [ -n "${SSH_CONNECTION:-}" ] && [ -z "${ZELLIJ:-}" ] && [ "${TERM:-}" != dumb ]; then
  # Attach to the most-recently-used session, or start a new one.
  # `-c` = create session if none exists; no session name = pick newest.
  exec zellij attach --create 2>/dev/null || exec zellij
fi
