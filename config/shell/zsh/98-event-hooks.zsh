# config/shell/zsh/98-event-hooks.zsh — dotfiles event hook system
# Allows registration of custom code at shell lifecycle points

# _event_hooks — registry of lifecycle hooks
declare -gA DOTFILES_EVENT_HOOKS

# add-dotfiles-hook EVENT CALLBACK
# Register a callback for a dotfiles event
add-dotfiles-hook() {
  local event=$1 callback=$2
  [ -z "$event" ] || [ -z "$callback" ] && return 1
  
  local key="${event}:${callback}"
  DOTFILES_EVENT_HOOKS[$key]="$callback"
}

# _trigger_hook EVENT — execute all registered callbacks for event
_trigger_hook() {
  local event=$1
  
  for key callback_name in "${(@kv)DOTFILES_EVENT_HOOKS}"; do
    local event_name="${key%:*}"
    [ "$event_name" = "$event" ] || continue
    
    # Execute callback if function exists
    (( ${+functions[$callback_name]} )) && $callback_name
  done
}

# Available events:
# - pre-shell:   Before prompt is shown (after all modules loaded)
# - post-command: After each command execution
# - module-loaded:NAME — After specific module loads
# - tool-init:NAME — After tool initializes

# Hook pre-shell event for custom initialization
add-zsh-hook precmd _trigger_pre_shell_hooks

_trigger_pre_shell_hooks() {
  # Only run once per session
  if [ -z "${DOTFILES_PRE_SHELL_RUN:-}" ]; then
    _trigger_hook "pre-shell"
    DOTFILES_PRE_SHELL_RUN=1
  fi
}

# Example usage:
# add-dotfiles-hook pre-shell "my-custom-init-function"
# add-dotfiles-hook post-command "track-command-stats"
