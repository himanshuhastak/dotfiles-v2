# glow — markdown renderer for the terminal.
command -v glow >/dev/null 2>&1 || return 0

alias mdcat='glow'

# Open markdown files in paged mode by default when piped to less/bat.
# glow -p paginates; use plain `glow FILE` for inline rendering.
md() {
  if [ $# -eq 0 ]; then
    # No args: render all .md in cwd as a list
    glow
  else
    glow -p "$@"
  fi
}
