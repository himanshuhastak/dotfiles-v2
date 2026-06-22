#!/usr/bin/env bash
# install/bin/generate-tool-inventory.sh — auto-generate TOOL_INVENTORY.md from config/tools.toml
set -uo pipefail

MANIFEST="${1:-$(cd "$(dirname "$0")/../.. && pwd)/config/tools.toml}"
OUTPUT="${2:-$(cd "$(dirname "$0")/../.. && pwd)/TOOL_INVENTORY.md}"

[ -r "$MANIFEST" ] || { echo "Error: $MANIFEST not found" >&2; exit 1; }

# --- simple TOML parser ---
# Extract all tools and their metadata
parse_tools() {
  local toml=$1
  awk '
    BEGIN {
      current_tool = ""
      in_tool = 0
    }
    /^\[\[tool\]\]/ {
      if (current_tool != "") print current_tool
      in_tool = 1
      current_tool = ""
      next
    }
    in_tool && /^name/ {
      match($0, /"([^"]+)"/, a)
      current_tool = a[1]
    }
    in_tool && /^repo/ {
      match($0, /"([^"]+)"/, a)
      repo = a[1]
      current_tool = current_tool "|" repo
    }
    in_tool && /^version/ {
      match($0, /"([^"]+)"/, a)
      version = a[1]
      current_tool = current_tool "|" version
    }
    in_tool && /^description/ {
      match($0, /"([^"]+)"/, a)
      desc = a[1]
      current_tool = current_tool "|" desc
    }
    in_tool && /^category/ {
      match($0, /"([^"]+)"/, a)
      cat = a[1]
      current_tool = current_tool "|" cat
    }
    in_tool && /^defer/ {
      if (/true/) defer = "deferred"
      else defer = "sync"
      current_tool = current_tool "|" defer
    }
    in_tool && /^optional/ {
      if (/true/) current_tool = current_tool "|optional"
    }
    in_tool && /^install_method/ {
      match($0, /"([^"]+)"/, a)
      method = a[1]
      current_tool = current_tool "|" method
    }
    END {
      if (current_tool != "") print current_tool
    }
  ' "$toml"
}

# --- generate markdown ---
{
  echo "# Tool Inventory"
  echo ""
  echo "Auto-generated from [config/tools.toml](config/tools.toml)"
  echo ""
  echo "## Summary"
  echo ""
  
  # Extract categories and count
  declare -A categories
  parse_tools "$MANIFEST" | while IFS='|' read -r name repo rest; do
    [ -z "$name" ] && continue
    echo "$repo" | grep -q '.' && continue
  done
  
  echo "Total: $(grep -c '^\[\[tool\]\]' "$MANIFEST") tools"
  echo ""
  echo "## Tools by Category"
  echo ""
  
  # Group by category
  last_category=""
  parse_tools "$MANIFEST" | while IFS='|' read -r name repo version desc category defer optional install_method; do
    [ -z "$name" ] && continue
    
    if [ "$category" != "$last_category" ]; then
      if [ -n "$last_category" ]; then
        echo ""
      fi
      echo "### $(echo "$category" | sed 's/^./\U&/' | sed 's/-/ /g')"
      echo ""
      last_category="$category"
    fi
    
    # Format tool entry
    printf "- **%s**" "$name"
    if [ -n "$version" ]; then
      printf " (%s)" "$version"
    fi
    if [ -n "$desc" ]; then
      printf " — %s" "$desc"
    fi
    
    # Add flags
    flags=""
    if [ "$optional" = "optional" ]; then
      flags="$flags [optional]"
    fi
    if [ "$defer" = "sync" ]; then
      flags="$flags [sync]"
    elif [ "$defer" = "deferred" ]; then
      flags="$flags [deferred]"
    fi
    if [ "$install_method" != "github" ] && [ -n "$install_method" ]; then
      flags="$flags [$install_method]"
    fi
    
    if [ -n "$flags" ]; then
      printf "%s" "$flags"
    fi
    
    if [ -n "$repo" ]; then
      printf " ([repo](https://github.com/%s))" "$repo"
    fi
    echo ""
  done
  
  echo ""
  echo "## Installation"
  echo ""
  echo "Tools are installed via:"
  echo ""
  echo "\`\`\`bash"
  echo "bash install/bin/install-from-manifest.sh"
  echo "\`\`\`"
  echo ""
  echo "Or as part of the full setup:"
  echo ""
  echo "\`\`\`bash"
  echo "./install.sh"
  echo "\`\`\`"
  echo ""
  echo "## Tool Categories"
  echo ""
  echo "- **productivity**: High-level task and workflow tools"
  echo "- **shell-enhancement**: Shell plugins and integrations"
  echo "- **utilities**: General-purpose CLI utilities"
  echo "- **git**: Git-related tools"
  echo "- **ui**: User interface tools (prompts, multiplexers)"
  echo "- **shells**: Shell environments"
  echo "- **development**: Development tools (linters, testers, formatters)"
  echo "- **languages**: Programming language toolchains"
  echo "- **navigation**: Directory and file navigation"
  echo ""
  
} > "$OUTPUT"

echo "Generated: $OUTPUT"
