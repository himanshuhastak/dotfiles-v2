#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
# broot ships one versioned zip bundling all arch builds; pick this arch's musl binary.
install_tool broot Canop/broot 'broot_{ver}.zip' broot '{arch}-unknown-linux-musl'
