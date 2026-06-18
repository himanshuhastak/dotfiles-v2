#!/usr/bin/env bash
# GNU parallel — run shell jobs in parallel (Perl; no musl/GitHub binary).
# Installs parallel, sem, niceload, sql from the official GNU release tarball.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

have parallel && { skip parallel; exit 0; }
command -v perl >/dev/null 2>&1 || { warn "parallel: perl required"; exit 1; }

ver="$(curl -fsSL --connect-timeout 20 "https://ftp.gnu.org/gnu/parallel/" 2>/dev/null \
  | grep -oE 'parallel-[0-9]{8}\.tar\.bz2' | sort -ru | head -n1 \
  | sed 's/parallel-//;s/\.tar\.bz2//')"
[ -n "$ver" ] || { warn "parallel: cannot resolve latest GNU version"; exit 1; }

url="https://ftp.gnu.org/gnu/parallel/parallel-${ver}.tar.bz2"
tmp="$(mktemp -d "$CACHE/parallel.XXXXXX")"
log "Installing GNU parallel $ver"
if curl -fL --retry 3 --connect-timeout 20 -o "$tmp/parallel.tar.bz2" "$url" \
   && tar -xjf "$tmp/parallel.tar.bz2" -C "$tmp"; then
  src="$tmp/parallel-$ver/src"
  for bin in parallel sem niceload sql; do
    [ -f "$src/$bin" ] || { warn "parallel: missing $bin in tarball"; exit 1; }
    install -m 0755 "$src/$bin" "$BIN/$bin"
  done
  rm -rf "$tmp" 2>/dev/null || true
  ok "parallel $ver -> $BIN/{parallel,sem,niceload,sql}"
else
  rm -rf "$tmp" 2>/dev/null || true
  warn "parallel: install failed"
  exit 1
fi
