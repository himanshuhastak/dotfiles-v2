#!/usr/bin/env bash
# install/bin/install-from-manifest.sh — install tools from config/tools.toml manifest
# Default: install GNU parallel first, then install remaining tools in parallel.
# Usage: install-from-manifest.sh [--sequential] [--save-lock]
#        PARALLEL_JOBS=N ./install-from-manifest.sh
set -uo pipefail

source "$(dirname "$0")/../common.sh"
export DOTFILES

MANIFEST="${DOTFILES}/config/tools.toml"
LOCK_FILE="${DOTFILES}/config/tools.lock"

# Auto-detect available CPU cores; cap at 8 to avoid overwhelming slow disks.
_cpu_count() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  elif command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.logicalcpu 2>/dev/null || echo 4
  else
    echo 4
  fi
}
_detected=$(( $(_cpu_count) > 8 ? 8 : $(_cpu_count) ))
PARALLEL_JOBS="${PARALLEL_JOBS:-$_detected}"
unset _detected

INSTALL_MODE="parallel"  # default; --sequential to opt out
SAVE_LOCK=0

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    --parallel)   INSTALL_MODE="parallel"; shift ;;
    --sequential) INSTALL_MODE="sequential"; shift ;;
    --save-lock)  SAVE_LOCK=1; shift ;;
    --auto)       INSTALL_MODE="parallel"; shift ;;  # legacy alias
    *)            break ;;
  esac
done

# --- TOML parsing (simple sed/awk-based, no external dependencies) -----------
# parse_tool_entries TOML_FILE — extract tool install blocks
# Output: name|repo|archive_pattern|binname|install_method per tool
parse_tool_entries() {
  local toml=$1
  [ -r "$toml" ] || return 1
  
  # Use gsub() instead of match() 3-arg form: portable across BSD awk (macOS)
  # and GNU awk. gsub strips everything before/after the quoted value.
  awk '
    /^\[\[tool\]\]/ {
      if (name != "") print name "|" repo "|" archive_pattern "|" binname "|" install_method
      name = repo = archive_pattern = binname = install_method = ""
      next
    }
    /^name[[:space:]]*=/ {
      v = $0; gsub(/^[^"]*"/, "", v); gsub(/".*/, "", v); name = v
    }
    /^repo[[:space:]]*=/ {
      v = $0; gsub(/^[^"]*"/, "", v); gsub(/".*/, "", v); repo = v
    }
    /^archive_pattern[[:space:]]*=/ {
      v = $0; gsub(/^[^"]*"/, "", v); gsub(/".*/, "", v); archive_pattern = v
    }
    /^binname[[:space:]]*=/ {
      v = $0; gsub(/^[^"]*"/, "", v); gsub(/".*/, "", v); binname = v
    }
    /^install_method[[:space:]]*=/ {
      v = $0; gsub(/^[^"]*"/, "", v); gsub(/".*/, "", v); install_method = v
    }
    END {
      if (name != "") print name "|" repo "|" archive_pattern "|" binname "|" install_method
    }
  ' "$toml"
}

# _install_one ENTRY — install a single manifest entry (safe for parallel workers).
# Each worker sources common.sh so helpers (skip, detect_arch, …) are available.
# Entry format: "name|repo|archive_pattern|binname|install_method"
_install_one() {
  local entry=$1
  local name repo archive_pattern binname install_method script
  local common="${DOTFILES}/install/common.sh"
  local tools="${DOTFILES}/install/tools"

  IFS='|' read -r name repo archive_pattern binname install_method <<<"$entry"
  [ -z "$repo" ] && return 0

  # Non-GitHub-release installs delegate to per-tool scripts (source, pip, git-clone, …).
  if [ -n "$install_method" ] && [ "$install_method" != "github" ]; then
    script="$tools/${name}.sh"
    if [ -f "$script" ]; then
      bash "$script" || return 1
    else
      # shellcheck disable=SC1090
      source "$common"
      warn "$name: install_method=$install_method but no installer at $script"
      return 1
    fi
    return 0
  fi

  if [ -z "$archive_pattern" ]; then
    # shellcheck disable=SC1090
    source "$common"
    warn "$name: no archive_pattern in manifest (skipped)"
    return 0
  fi

  # shellcheck disable=SC1090
  source "$common"
  init_tools_dir
  install_tool "$name" "$repo" "$archive_pattern" "${binname:-$name}"
}

export -f _install_one

# _parallel_entry ENTRIES — print the manifest line for GNU parallel, if any.
_parallel_entry() {
  printf '%s\n' "$1" | awk -F'|' '$1=="parallel"{print; exit}'
}

# _ensure_gnu_parallel ENTRIES — bootstrap GNU parallel into $BIN before batch install.
_ensure_gnu_parallel() {
  local entries=$1 entry
  command -v parallel >/dev/null 2>&1 && return 0
  entry="$(_parallel_entry "$entries")"
  [ -n "$entry" ] || { warn "parallel not on PATH and no manifest entry"; return 1; }
  log "Installing GNU parallel first (bootstrap for parallel installs)"
  _install_one "$entry" || return 1
  command -v parallel >/dev/null 2>&1 || return 1
  # Silence the academic citation notice on every run (one-time per user; harmless if repeated).
  parallel --citation </dev/null >/dev/null 2>&1 || true
}

# _run_parallel_batch BATCH — install manifest lines with GNU parallel or xargs -P.
_run_parallel_batch() {
  local batch=$1
  if command -v parallel >/dev/null 2>&1; then
    printf '%s\n' "$batch" | parallel -j "$PARALLEL_JOBS" --halt soon,fail=1 _install_one
  elif command -v xargs >/dev/null 2>&1; then
    warn "GNU parallel unavailable; using xargs -P"
    printf '%s\n' "$batch" | xargs -P "$PARALLEL_JOBS" -I {} bash -c '_install_one "$@"' _ {}
  else
    warn "parallel and xargs unavailable; falling back to sequential"
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      _install_one "$entry" || return 1
    done <<<"$batch"
  fi
}

# --- main --------------------------------------------------------------------
log "Installing tools from manifest: $MANIFEST"
init_tools_dir

# Parse manifest
entries=$(parse_tool_entries "$MANIFEST")
entry_count=$(echo "$entries" | wc -l)
log "Found $entry_count tools to install"

# Execute installation
case "$INSTALL_MODE" in
  parallel)
    log "Installing in parallel (${PARALLEL_JOBS} concurrent jobs)"
    _ensure_gnu_parallel "$entries" || true
    _run_parallel_batch "$entries"
    ;;
  sequential)
    log "Installing sequentially"
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      _install_one "$entry" || { warn "Failed to install from entry: $entry"; }
    done <<<"$entries"
    ;;
  *)
    die "unknown install mode: $INSTALL_MODE (use: parallel, sequential)"
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
