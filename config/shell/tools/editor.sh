# `g` — smart editor launcher: cursor/code inside VS Code/Cursor terminals,
# otherwise a GUI/terminal vim. Portable (works in any interactive shell).
if [ "$TERM_PROGRAM" = "vscode" ]; then
  if command -v cursor >/dev/null 2>&1; then
    alias g='cursor'
  elif command -v code >/dev/null 2>&1; then alias g='code'; fi
else
  if command -v gvim >/dev/null 2>&1; then
    alias g='gvim'
  elif command -v vim >/dev/null 2>&1; then alias g='vim'; fi
fi
