#!/usr/bin/env bash
# zsh — build latest stable release into .tools (optional upgrade over system zsh).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

if [ -x "$BIN/zsh" ]; then
  cur="$("$BIN/zsh" --version 2>/dev/null | awk '{print $2}')"
  case "$cur" in
    5.[89]*|5.1[0-9]*) skip "zsh $cur"; exit 0 ;;
  esac
fi

for cmd in gcc make curl; do
  command -v "$cmd" >/dev/null 2>&1 || { warn "zsh: $cmd required"; exit 1; }
done

resolve_zsh_url() {
  local v url
  # Probe recent stable releases (zsh.org is canonical; SourceForge is the mirror).
  for v in 5.9 5.8 5.7; do
    for url in \
      "https://www.zsh.org/pub/zsh-${v}.tar.xz" \
      "https://downloads.sourceforge.net/project/zsh/zsh/${v}/zsh-${v}.tar.xz"; do
      if curl -fsSLI --connect-timeout 15 "$url" 2>/dev/null \
         | head -n1 | grep -q '200\|302'; then
        printf '%s %s\n' "$v" "$url"
        return 0
      fi
    done
  done
  return 1
}

read -r ver url < <(resolve_zsh_url) || { warn "zsh: cannot resolve latest version"; exit 1; }

prefix="$TOOLS_DIR/pkg/zsh"
tmp="$(mktemp -d "$CACHE/zsh.XXXXXX")"
log "Building zsh $ver (this can take a few minutes)"
if curl -fL --retry 3 --connect-timeout 30 -o "$tmp/zsh.tar.xz" "$url" \
   && tar -xJf "$tmp/zsh.tar.xz" -C "$tmp"; then
  (
    cd "$tmp/zsh-$ver"
    ./configure --prefix="$prefix" --enable-pcre --enable-cap --enable-multibyte \
      --without-tcsetpgrp >/dev/null
    make -j"$(nproc 2>/dev/null || echo 2)" >/dev/null
    make install >/dev/null
  ) || { rm -rf "$tmp" 2>/dev/null || true; warn "zsh: build failed"; exit 1; }
  rm -rf "$tmp" 2>/dev/null || true
  [ -x "$prefix/bin/zsh" ] || { warn "zsh: install missing $prefix/bin/zsh"; exit 1; }
  ln -sf "$prefix/bin/zsh" "$BIN/zsh"
  ok "zsh $ver -> $BIN/zsh"
else
  rm -rf "$tmp" 2>/dev/null || true
  warn "zsh: download failed"
  exit 1
fi
