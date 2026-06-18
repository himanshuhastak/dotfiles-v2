#!/usr/bin/env bash
# editorconfig-checker (editorconfig-checker/editorconfig-checker) — verify files
# obey .editorconfig. The release tarball ships bin/ec-linux-<arch>; install that
# and add friendly `editorconfig-checker` + `ec` names.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
have editorconfig-checker && { skip editorconfig-checker; exit 0; }
case "$(uname -m)" in
  x86_64|amd64)  a=amd64 ;;
  aarch64|arm64) a=arm64 ;;
  *) warn "editorconfig-checker: unsupported arch $(uname -m)"; exit 1 ;;
esac
download_url editorconfig-checker \
  "https://github.com/editorconfig-checker/editorconfig-checker/releases/latest/download/ec-linux-${a}.tar.gz" \
  "ec-linux-${a}"
ln -sf "ec-linux-${a}" "$BIN/editorconfig-checker"
ln -sf "ec-linux-${a}" "$BIN/ec"
ok "editorconfig-checker -> $BIN/editorconfig-checker (+ ec)"
