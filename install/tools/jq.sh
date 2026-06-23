#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
[ -x "$BIN/jq" ] && { skip jq; exit 0; }
goarch="$(go_arch)" || exit 1
download_url jq "https://github.com/jqlang/jq/releases/latest/download/jq-linux-${goarch}" jq
