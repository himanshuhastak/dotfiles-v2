#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool lazygit jesseduffield/lazygit 'lazygit_{ver}_Linux_{arch}.tar.gz'
