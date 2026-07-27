#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool bat sharkdp/bat 'bat-{tag}-{arch}-unknown-linux-musl.tar.gz'
