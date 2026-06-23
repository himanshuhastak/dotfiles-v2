#!/usr/bin/env bash
# install/bin/install-from-manifest.sh — install tools from config/tools.toml manifest
# Default: install GNU parallel first, then install remaining tools in parallel.
# Usage: install-from-manifest.sh [--sequential] [--with-optional] [--save-lock]
#        PARALLEL_JOBS=N INSTALL_OPTIONAL=1 ./install-from-manifest.sh
set -uo pipefail

source "$(dirname "$0")/../common.sh"
export DOTFILES

# Site/cluster PARALLEL_* env (e.g. --joblog, --results) must not leak into our installer.
unset PARALLEL PARALLEL_OPTS 2>/dev/null || true

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
INSTALL_OPTIONAL="${INSTALL_OPTIONAL:-0}"
SAVE_LOCK=0

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    --parallel)       INSTALL_MODE="parallel"; shift ;;
    --sequential)     INSTALL_MODE="sequential"; shift ;;
    --with-optional)  INSTALL_OPTIONAL=1; shift ;;
    --save-lock)      SAVE_LOCK=1; shift ;;
    --auto)           INSTALL_MODE="parallel"; shift ;;  # legacy alias
    *)                break ;;
  esac
done

# --- TOML parsing (simple sed/awk-based, no external dependencies) -----------
# parse_tool_entries TOML_FILE — extract tool install blocks
# Output: name|repo|archive_pattern|binname|install_method|optional|path_hint
parse_tool_entries() {
  local toml=$1
  [ -r "$toml" ] || return 1
  
  awk '
    /^\[\[tool\]\]/ {
      if (name != "") print name "|" repo "|" archive_pattern "|" binname "|" install_method "|" optional "|" path_hint
      name = repo = archive_pattern = binname = install_method = path_hint = ""
      optional = "0"
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
    /^path_hint[[:space:]]*=/ {
      v = $0; gsub(/^[^"]*"/, "", v); gsub(/".*/, "", v); path_hint = v
    }
    /^optional[[:space:]]*=/ {
      if ($0 ~ /true/) optional = "1"
    }
    END {
      if (name != "") print name "|" repo "|" archive_pattern "|" binname "|" install_method "|" optional "|" path_hint
    }
  ' "$toml"
}

# _install_one ENTRY — install a single manifest entry (safe for parallel workers).
# Each worker sources common.sh so helpers (skip, detect_arch, …) are available.
# Entry format: "name|repo|archive_pattern|binname|install_method|optional|path_hint"
_install_one() {
  local entry=$1
  local name repo archive_pattern binname install_method optional path_hint script
  local common="${DOTFILES}/install/common.sh"
  local tools="${DOTFILES}/install/tools"

  IFS='|' read -r name repo archive_pattern binname install_method optional path_hint <<<"$entry"
  [ -z "$repo" ] && return 0

  # Non-GitHub-release installs delegate to per-tool scripts (source, pip, script, …).
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
  install_tool "$name" "$repo" "$archive_pattern" "${binname:-$name}" "${path_hint:-}"
}

# _ensure_gnu_parallel — bootstrap GNU parallel into $BIN before batch install.
_ensure_gnu_parallel() {
  local script="${DOTFILES}/install/tools/parallel.sh"
  command -v parallel >/dev/null 2>&1 && return 0
  [ -f "$script" ] || { warn "parallel bootstrap script missing ($script)"; return 1; }
  log "Installing GNU parallel first (bootstrap for parallel installs)"
  bash "$script" || return 1
  command -v parallel >/dev/null 2>&1 || return 1
  parallel --citation </dev/null >/dev/null 2>&1 || true
}

# _run_parallel_batch BATCH — install manifest lines with GNU parallel or xargs -P.
_run_parallel_batch() {
  local batch=$1 worker="$DOTFILES/install/bin/install-one-entry.sh"
  [ -r "$worker" ] || { warn "missing parallel worker: $worker"; return 1; }
  if command -v parallel >/dev/null 2>&1; then
    printf '%s\n' "$batch" | parallel -j "$PARALLEL_JOBS" --halt soon,fail=1 \
      bash "$worker" {}
  elif command -v xargs >/dev/null 2>&1; then
    warn "GNU parallel unavailable; using xargs -P"
    printf '%s\n' "$batch" | xargs -P "$PARALLEL_JOBS" -I {} bash "$worker" {}
  else
    warn "parallel and xargs unavailable; falling back to sequential"
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      bash "$worker" "$entry" || return 1
    done <<<"$batch"
  fi
}

# --- main --------------------------------------------------------------------
log "Installing tools from manifest: $MANIFEST"
init_tools_dir

# Parse manifest
entries=$(parse_tool_entries "$MANIFEST")
if [ "$INSTALL_OPTIONAL" != "1" ]; then
  optional_skipped=$(printf '%s\n' "$entries" | awk -F'|' '$6=="1"{c++} END{print c+0}')
  entries=$(printf '%s\n' "$entries" | awk -F'|' '$6!="1"{print}')
  [ "${optional_skipped:-0}" -gt 0 ] && \
    log "Skipping $optional_skipped optional tool(s) (bash, ble.sh, rust, task, timew, …); use --with-optional to include"
fi
entry_count=$(printf '%s\n' "$entries" | grep -c . || true)
log "Found $entry_count tools to install"

# Execute installation
case "$INSTALL_MODE" in
  parallel)
    log "Installing in parallel (${PARALLEL_JOBS} concurrent jobs)"
    _ensure_gnu_parallel || true
    _run_parallel_batch "$entries"
    ;;
  sequential)
    log "Installing sequentially"
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      bash "$DOTFILES/install/bin/install-one-entry.sh" "$entry" || \
        { warn "Failed to install from entry: $entry"; }
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
