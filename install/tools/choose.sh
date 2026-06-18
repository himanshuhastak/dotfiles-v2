#!/usr/bin/env bash
# choose — column/field picker for piped text (Rust).
# x86_64: static musl; aarch64: gnu only (no musl release published).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

if have choose; then skip choose; exit 0; fi

arch="$(detect_arch)" || exit 1
case "$arch" in
  x86_64)  asset="choose-x86_64-unknown-linux-musl" ;;
  aarch64) asset="choose-aarch64-unknown-linux-gnu" ;;
  *) warn "choose: unsupported arch $arch"; exit 1 ;;
esac

download_url choose \
  "https://github.com/theryangeary/choose/releases/latest/download/$asset" \
  choose
