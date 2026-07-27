#!/usr/bin/env bash
# install/tools/chezmoi.sh — chezmoi dotfile manager (replaces GNU stow for $HOME files).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool chezmoi twpayne/chezmoi 'chezmoi_{ver}_linux-musl_{goarch}.tar.gz'
