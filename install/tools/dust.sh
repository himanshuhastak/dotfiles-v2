#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool dust bootandy/dust 'dust-{tag}-{arch}-unknown-linux-musl.tar.gz'
