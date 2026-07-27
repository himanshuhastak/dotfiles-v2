# config/shell/zsh/97-session-state.zsh — runtime session tracking
# Track which modules/tools have been loaded for introspection

# Declare tracking arrays
declare -gA DOTFILES_LOADED     # Module -> load_time_ms
declare -gA DOTFILES_TOOLS      # Tool -> initialized|failed
declare -gA DOTFILES_HOOKS      # Hook -> callback_function

# _session_state_init — initialize session tracking
# Uses $EPOCHSECONDS from zsh/datetime (loaded in 02-zmodload.zsh) — no fork.
_session_state_init() {
  DOTFILES_LOADED[_started]=$EPOCHSECONDS
}

# _track_module NAME — mark module as loaded
# Called by _load_file; uses $EPOCHSECONDS (integer seconds, no subshell fork).
_track_module() {
  local name=$1
  DOTFILES_LOADED[$name]=$EPOCHSECONDS
}

# _track_tool NAME STATUS — mark tool as initialized
_track_tool() {
  local tool=$1 status=$2
  DOTFILES_TOOLS[$tool]="$status"
}

# Session introspection functions
dotfiles_loaded_modules() {
  printf '%s: %s\n' "${(@kv)DOTFILES_LOADED}"
}

dotfiles_loaded_tools() {
  printf '%s -> %s\n' "${(@kv)DOTFILES_TOOLS}"
}

dotfiles_session_summary() {
  echo "=== Session Summary ==="
  echo "Loaded modules: ${#DOTFILES_LOADED[@]}"
  echo "Initialized tools: ${#DOTFILES_TOOLS[@]}"
  echo ""
  
  local failed_tools=0
  for tool status in "${(@kv)DOTFILES_TOOLS}"; do
    [ "$status" = "failed" ] && failed_tools=$((failed_tools + 1))
  done
  
  [ "$failed_tools" -gt 0 ] && \
    echo "⚠ $failed_tools tool(s) failed to initialize"
}

# Initialize on shell startup
_session_state_init
