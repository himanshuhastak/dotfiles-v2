#!/usr/bin/env bash
# bats-core — the bash test framework used by `dotfiles test`. It's a set of
# shell scripts (not a single binary), so install via its own install.sh into
# the tools pkg dir and symlink the launcher into $BIN.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
have bats && { skip bats; exit 0; }

tag="$(gh_latest_tag bats-core/bats-core)" || { warn "bats: cannot resolve version"; exit 1; }
ver="${tag#v}"
tmp="$(mktemp -d "$CACHE/bats.XXXXXX")"
log "Installing bats $ver"
if ! curl -fL --retry 3 --connect-timeout 20 -o "$tmp/bats.tar.gz" \
     "https://github.com/bats-core/bats-core/archive/refs/tags/$tag.tar.gz"; then
  rm -rf "$tmp"; warn "bats: download failed"; exit 1
fi
tar -xzf "$tmp/bats.tar.gz" -C "$tmp"
src="$tmp/bats-core-$ver"
prefix="$TOOLS_DIR/pkg/bats"
if "$src/install.sh" "$prefix" >/dev/null 2>&1 && [ -x "$prefix/bin/bats" ]; then
  ln -sf "$prefix/bin/bats" "$BIN/bats"
  rm -rf "$tmp"
  ok "bats -> $BIN/bats"
else
  rm -rf "$tmp"; warn "bats: install failed"; exit 1
fi
