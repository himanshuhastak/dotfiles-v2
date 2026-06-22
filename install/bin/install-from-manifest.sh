#!/usr/bin/env bash
# install/bin/install-from-manifest.sh — install tools from config/tools.toml manifest
# Supports sequential or parallel installation (if GNU parallel/xargs available).
set -uo pipefail

source "$(dirname "$0")/../common.sh"

MANIFEST="${DOTFILES}/config/tools.toml"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"  # default 4 concurrent installs
PARALLEL_MODE="${PARALLEL_MODE:-auto}"  # auto, parallel, sequential

# --- TOML parsing (simple sed/awk-based, no external dependencies) -----------
# parse_tool_entries TOML_FILE — extract tool install blocks
# Output: lines like "name:repo:archive_pattern:binname" for each tool
parse_tool_entries() {
  local toml=$1
  [ -r "$toml" ] || return 1
  
  local name repo archive_pattern binname
  local in_tool=0
  
  while IFS= read -r line; do
    # Start of a [[tool]] block
    if [[ "$line" == '[[tool]]'* ]]; then
      [ $in_tool -eq 1 ] && [ -n "$name" ] && printf '%s\n' "$name:${repo:-}:${archive_pattern:-}:${binname:-$name}"
      in_tool=1
      name= repo= archive_pattern= binname=
      continue
    fi
    
    [ $in_tool -eq 0 ] && continue
    
    # Parse key = value lines
    if [[ "$line" =~ ^name[[:space:]]*=[[:space:]]*\"(.+)\" ]]; then
      name="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^repo[[:space:]]*=[[:space:]]*\"(.+)\" ]]; then
      repo="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^archive_pattern[[:space:]]*=[[:space:]]*\"(.+)\" ]]; then
      archive_pattern="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^binname[[:space:]]*=[[:space:]]*\"(.+)\" ]]; then
      binname="${BASH_REMATCH[1]}"
    fi
  done <"$toml"
  
  # Output the last tool
  [ $in_tool -eq 1 ] && [ -n "$name" ] && printf '%s\n' "$name:${repo:-}:${archive_pattern:-}:${binname:-$name}"
}

# install_tool_from_entry ENTRY — extract fields and call install_tool
# Entry format: "name:repo:archive_pattern:binname"
install_tool_from_entry() {
  local entry=$1
  IFS=':' read -r name repo archive_pattern binname <<<"$entry"
  
  # Skip tools without repos (source installs, etc.)
  [ -z "$repo" ] && { log "Skipping $name (special install method)"; return 0; }
  
  install_tool "$name" "$repo" "$archive_pattern" "$binname"
}

# --- main --------------------------------------------------------------------
log "Installing tools from manifest: $MANIFEST"
init_tools_dir

# Detect if parallel is available
have_parallel() {
  command -v parallel >/dev/null 2>&1 || command -v xargs >/dev/null 2>&1
}

# Parse manifest and decide on mode
entries=$(parse_tool_entries "$MANIFEST")
entry_count=$(wc -l <<<"$entries")
log "Found $entry_count tools to install"

case "$PARALLEL_MODE" in
  auto)
    if [ "$entry_count" -gt 5 ] && have_parallel; then
      log "Installing in parallel (${PARALLEL_JOBS} jobs)"
      if command -v parallel >/dev/null 2>&1; then
        export -f install_tool_from_entry install_tool download_url have
        printf '%s\n' "$entries" | parallel -j "$PARALLEL_JOBS" install_tool_from_entry
      else
        printf '%s\n' "$entries" | xargs -P "$PARALLEL_JOBS" -I {} bash -c 'install_tool_from_entry "$@"' _ {}
      fi
    else
      while IFS= read -r entry; do
        install_tool_from_entry "$entry"
      done <<<"$entries"
    fi
    ;;
  parallel)
    export -f install_tool_from_entry install_tool download_url have
    printf '%s\n' "$entries" | parallel -j "$PARALLEL_JOBS" install_tool_from_entry
    ;;
  sequential)
    while IFS= read -r entry; do
      install_tool_from_entry "$entry"
    done <<<"$entries"
    ;;
  *)
    die "unknown PARALLEL_MODE: $PARALLEL_MODE (use: auto, parallel, sequential)"
    ;;
esac

ok "Tool installation from manifest complete"
