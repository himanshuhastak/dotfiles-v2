# watchexec — re-run commands when files change.
command -v watchexec >/dev/null 2>&1 || return 0

alias we='watchexec'
# Convenience: watch-run <ext> <cmd> — re-run CMD when any *.<ext> file changes.
watch-run() {
  local ext="${1:?Usage: watch-run <ext> <cmd...>}"; shift
  watchexec --exts "$ext" -- "$@"
}
