#!/usr/bin/env bash
# GNU bash — build latest release into .tools (system RHEL bash is often 4.x).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

if [ -x "$BIN/bash" ]; then
  cur="$("$BIN/bash" --version 2>/dev/null | awk 'NR==1 {gsub(/[()]/,"",$4); print $4}')"
  case "$cur" in
    5.*) skip "bash $cur"; exit 0 ;;
  esac
fi

for cmd in gcc make curl; do
  command -v "$cmd" >/dev/null 2>&1 || { warn "bash: $cmd required"; exit 1; }
done

ver="$(curl -fsSL --connect-timeout 20 "https://ftp.gnu.org/gnu/bash/" 2>/dev/null \
  | grep -oE 'bash-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' \
  | sed 's/\.tar\.gz//' | sort -V | tail -n1 | sed 's/^bash-//')"
[ -n "$ver" ] || { warn "bash: cannot resolve latest GNU version"; exit 1; }

prefix="$TOOLS_DIR/pkg/bash"
url="https://ftp.gnu.org/gnu/bash/bash-${ver}.tar.gz"
tmp="$(mktemp -d "$CACHE/bash.XXXXXX")"
log "Building GNU bash $ver (this can take a few minutes)"
if curl -fL --retry 3 --connect-timeout 20 -o "$tmp/bash.tar.gz" "$url" \
   && tar -xzf "$tmp/bash.tar.gz" -C "$tmp"; then
  (
    cd "$tmp/bash-$ver"
    ./configure --prefix="$prefix" >/dev/null
    make -j"$(nproc 2>/dev/null || echo 2)" >/dev/null
    make install >/dev/null
  ) || { rm -rf "$tmp" 2>/dev/null || true; warn "bash: build failed"; exit 1; }
  rm -rf "$tmp" 2>/dev/null || true
  [ -x "$prefix/bin/bash" ] || { warn "bash: install missing $prefix/bin/bash"; exit 1; }
  ln -sf "$prefix/bin/bash" "$BIN/bash"
  ok "bash $ver -> $BIN/bash"
else
  rm -rf "$tmp" 2>/dev/null || true
  warn "bash: download failed"
  exit 1
fi
