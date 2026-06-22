#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool atuin atuinsh/atuin 'atuin-{arch}-unknown-linux-musl.tar.gz'
