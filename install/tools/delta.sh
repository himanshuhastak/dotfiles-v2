#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool delta dandavison/delta 'delta-{ver}-{arch}-unknown-linux-musl.tar.gz'
