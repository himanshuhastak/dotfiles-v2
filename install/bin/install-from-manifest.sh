#!/usr/bin/env bash
# install/bin/install-from-manifest.sh — install tools from config/tools.toml manifest
# Supports sequential or parallel installation (if GNU parallel/xargs available).
# Usage: install-from-manifest.sh [--parallel | --sequential] [--save-lock]
#        PARALLEL_JOBS=N ./install-from-manifest.sh
set -uo pipefail

source "$(dirname "$0")/../common.sh"

MANIFEST="${DOTFILES}/config/tools.toml"
LOCK_FILE="${DOTFILES}/config/tools.lock"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"  # default 4 concurrent installs
INSTALL_MODE="auto"  # auto, parallel, sequential
SAVE_LOCK=0

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    --parallel)   INSTALL_MODE="parallel"; shift ;;
    --sequential) INSTALL_MODE="sequential"; shift ;;
    --save-lock)  SAVE_LOCK=1; shift ;;
    --auto)       INSTALL_MODE="auto"; shift ;;
    *)            break ;;
  esac
done

# --- TOML parsing (simple sed/awk-based, no external dependencies) -----------
# parse_tool_entries TOML_FILE — extract tool install blocks
# Output: lines like "name:repo:archive_pattern:binname" for each tool
parse_tool_entries() {
  local toml=$1
  [ -r "$toml" ] || return 1
  
  awk '
    /^\[\[tool\]\]/ {
      if (name != "") print name "|" repo "|" archive_pattern "|" binname
      name = repo = archive_pattern = binname = ""
      next
    }
    /^name[[:space:]]*=/ {
      match($0, /"([^"]+)"/, a)
      name = a[1]
    }
    /^repo[[:space:]]*=/ {
      match($0, /"([^"]+)"/, a)
      repo = a[1]
    }
    /^archive_pattern[[:space:]]*=/ {
      match($0, /"([^"]+)"/, a)
      archive_pattern = a[1]
    }
    /^binname[[:space:]]*=/ {
      match($0, /"([^"]+)"/, a)
      binname = a[1]
    }
    END {
      if (name != "") print name "|" repo "|" archive_pattern "|" binname
    }
  ' "$toml"
}

# install_tool_from_entry ENTRY — extract fields and call install_tool
# Entry format: "name|repo|archive_pattern|binname"
install_tool_from_entry() {
  local entry=$1
  local name repo archive_pattern binname
  
  IFS='|' read -r name repo archive_pattern binname <<<"$entry"
  
  # Skip tools without repos (source installs, etc.)
  if [ -z "$repo" ]; then
    return 0
  fi
  
  install_tool "$name" "$repo" "$archive_pattern" "$binname"
}

# export for parallel execution
export -f install_tool_from_entry install_tool download_url have

# --- main --------------------------------------------------------------------
log "Installing tools from manifest: $MANIFEST"
init_tools_dir

# Parse manifest
entries=$(parse_tool_entries "$MANIFEST")
entry_count=$(echo "$entries" | wc -l)
log "Found $entry_count tools to install"

# Detect if parallel is available
have_parallel() {
  command -v parallel >/dev/null 2>&1 && return 0
  command -v xargs >/dev/null 2>&1 && return 0
  return 1
}

# Determine installation mode
case "${INSTALL_MODE}" in
  --parallel)
    INSTALL_MODE="parallel"
    ;;
  --sequential)
    INSTALL_MODE="sequential"
    ;;
  auto)
    if [ "$entry_count" -gt 5 ] && have_parallel; then
      INSTALL_MODE="parallel"
    else
      INSTALL_MODE="sequential"
    fi
    ;;
esac

# Execute installation
case "$INSTALL_MODE" in
  parallel)
    log "Installing in parallel (${PARALLEL_JOBS} concurrent jobs)"
    if command -v parallel >/dev/null 2>&1; then
      # Use GNU parallel (most efficient)
      printf '%s\n' "$entries" | parallel -j "$PARALLEL_JOBS" --halt soon,fail=1 install_tool_from_entry
    else
      # Fall back to xargs
      printf '%s\n' "$entries" | xargs -P "$PARALLEL_JOBS" -I {} bash -c 'install_tool_from_entry "$@"' _ {}
    fi
    ;;
  sequential)
    log "Installing sequentially"
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      install_tool_from_entry "$entry" || { warn "Failed to install from entry: $entry"; }
    done <<<"$entries"
    ;;
  *)
    die "unknown install mode: $INSTALL_MODE (use: auto, parallel, sequential)"
    ;;
esac

ok "Tool installation from manifest complete"

# Update lock file if requested
if [ $SAVE_LOCK -eq 1 ]; then
  log "Updating lock file: $LOCK_FILE"
  {
    printf '[meta]\n'
    printf 'generated_at = "%s"\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'lock_version = "1.0"\n'
    printf '\n'
    
    while IFS='|' read -r name repo archive pattern binname; do
      [ -z "$name" ] && continue
      
      # Try to get version
      local version=""
      if command -v "$name" >/dev/null 2>&1; then
        version=$($name --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
      fi
      
      printf '[tool.%s]\n' "$name"
      printf 'version = "%s"\n' "${version:-unknown}"
      printf 'installed_at = "%s"\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      printf '\n'
    done <<<"$entries"
  } > "$LOCK_FILE"
  ok "Lock file updated: $LOCK_FILE"
fi
