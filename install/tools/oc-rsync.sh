#!/usr/bin/env bash
# oc-rsync — Rust rsync (wire-compatible with rsync 3.4.1). Installed as
# `oc-rsync` side-by-side with system rsync (does not shadow it).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool oc-rsync oferchen/rsync \
  'oc-rsync-{ver}-linux-{arch}-musl.tar.gz' oc-rsync
