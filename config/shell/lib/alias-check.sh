#!/usr/bin/env bash
# config/shell/lib/alias-check.sh — detect and report conflicting aliases
# Called from dotfiles check or interactively

# _check_aliases — detect duplicate/conflicting aliases
_check_aliases() {
  local aliases_file="${1:-.dotfiles-alias-check}"

  # Collect all defined aliases with their sources
  declare -gA ALIAS_DEFS # alias_name -> file:line

  # Scan all config files for alias definitions
  while IFS= read -r line; do
    if [[ "$line" =~ ^alias[[:space:]]+([a-zA-Z0-9_-]+)= ]]; then
      local alias_name="${BASH_REMATCH[1]}"
      local source_file="$REPLY" # From find -print0 | while read -d ''

      if [ -n "${ALIAS_DEFS[$alias_name]:-}" ]; then
        # Conflict detected
        echo "CONFLICT: '$alias_name' defined in:"
        echo "  1. ${ALIAS_DEFS[$alias_name]}"
        echo "  2. $source_file"
      else
        ALIAS_DEFS[$alias_name]="$source_file"
      fi
    fi
  done < <(
    find "$DOTFILES_DIR/config/shell" "$DOTFILES_LOCAL/profile" \
      -type f \( -name '*.sh' -o -name '*.zsh' \) \
      -exec grep -H "^alias " {} + 2>/dev/null | cut -d: -f1-2
  )

  # Summary
  local conflicts=0
  for alias_name in "${!ALIAS_DEFS[@]}"; do
    if grep -q "^alias $alias_name=" "$DOTFILES_DIR/config/shell"/*/* "$DOTFILES_LOCAL/profile"/* 2>/dev/null; then
      conflicts=$((conflicts + 1))
    fi
  done

  [ "$conflicts" -eq 0 ] && echo "✓ No alias conflicts detected" ||
    echo "⚠ $conflicts alias conflict(s) detected"
}

# Call from dotfiles check
if [ "${1:-}" = "check-aliases" ]; then
  _check_aliases
fi
