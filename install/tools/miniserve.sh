#!/usr/bin/env bash
# miniserve — tiny HTTP file server (Rust, static musl binary).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool miniserve svenstaro/miniserve \
  'miniserve-{ver}-{arch}-unknown-linux-musl' miniserve
