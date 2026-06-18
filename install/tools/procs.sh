#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool procs dalance/procs 'procs-{tag}-{arch}-linux.zip'
