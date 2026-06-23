#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
have gdu && { skip gdu; exit 0; }
ga="$(go_arch)" || exit 1
# gdu ships a versionless tgz whose binary is named gdu_linux_<arch>; rename it.
download_url gdu "https://github.com/dundee/gdu/releases/latest/download/gdu_linux_${ga}.tgz" "gdu_linux_${ga}"
[ -f "$BIN/gdu_linux_${ga}" ] && mv -f "$BIN/gdu_linux_${ga}" "$BIN/gdu" && ok "gdu -> $BIN/gdu"
