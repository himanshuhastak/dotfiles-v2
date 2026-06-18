#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
# tealdeer = fast Rust tldr client; install its raw binary as `tldr`.
install_tool tldr dbrgn/tealdeer 'tealdeer-linux-{arch}-musl' tldr
