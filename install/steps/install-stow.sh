#!/usr/bin/env bash
# Vendor stow-python (no Perl needed): https://github.com/isarandi/stow-python
set -euo pipefail
source "$(dirname "$0")/../common.sh"

mkdir -p "$DOTFILES/install/bin"
if [ ! -f "$DOTFILES/install/bin/stow.py" ]; then
  log "Fetching stow-python"
  curl -fsSL -o "$DOTFILES/install/bin/stow.py" \
    https://raw.githubusercontent.com/isarandi/stow-python/main/bin/stow
  # box has python3 but no `python`; pin the shebang.
  sed -i '1s|python$|python3|' "$DOTFILES/install/bin/stow.py"
fi
if [ ! -x "$DOTFILES/install/bin/stow" ]; then
  cat > "$DOTFILES/install/bin/stow" <<'EOF'
#!/usr/bin/env bash
exec python3 "$(dirname "$0")/stow.py" "$@"
EOF
  chmod +x "$DOTFILES/install/bin/stow"
fi
ok "stow-python -> $DOTFILES/install/bin/stow"
