#!/usr/bin/env bash
# taskwarrior-tui (tt) — terminal UI for taskwarrior. Rust musl static binary.
# Needs `task` to be useful.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool taskwarrior-tui kdheepak/taskwarrior-tui \
  'taskwarrior-tui-{arch}-unknown-linux-musl.tar.gz' taskwarrior-tui
