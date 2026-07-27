#!/usr/bin/env bash
# zshellcheck (afadesigns/zshellcheck) — static-analysis linter for zsh.
# Release assets are named with x86_64 / arm64 (no version in the name), so the
# /latest/download/ redirect works without an API call.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
have zshellcheck && {
  skip zshellcheck
  exit 0
}
case "$(uname -m)" in
  x86_64 | amd64) a=x86_64 ;;
  aarch64 | arm64) a=arm64 ;;
  *)
    warn "zshellcheck: unsupported arch $(uname -m)"
    exit 1
    ;;
esac
download_url zshellcheck \
  "https://github.com/afadesigns/zshellcheck/releases/latest/download/zshellcheck_Linux_${a}.tar.gz" \
  zshellcheck
