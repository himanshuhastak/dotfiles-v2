#!/usr/bin/env bash
# pipr — interactive shell pipeline builder (Rust).
# Prefer the prebuilt static binary from GitHub (x86_64 only); fall back to
# cargo on other arches. Needs bubblewrap (bwrap) for sandboxed eval, or use
# pipr --no-isolation.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

have pipr && { skip pipr; exit 0; }

arch="$(detect_arch)" || exit 1
tag="$(gh_latest_tag ElKowar/pipr)" || true
[ -n "$tag" ] || tag="v0.0.16"

if [ "$arch" = x86_64 ]; then
  if download_url pipr \
       "https://github.com/ElKowar/pipr/releases/download/$tag/pipr" \
       pipr; then
    command -v bwrap >/dev/null 2>&1 \
      || warn "pipr: install bubblewrap (bwrap) for sandboxed eval, or use --no-isolation"
    exit 0
  fi
  warn "pipr: prebuilt download failed; trying cargo"
fi

command -v cargo >/dev/null 2>&1 || ensure_rust || { warn "pipr: cargo (rust) required on $arch"; exit 1; }

prefix="$TOOLS_DIR/pkg/pipr"
log "Installing pipr $tag via cargo (may take a few minutes)"
mkdir -p "$prefix" "$BIN"
if cargo install pipr \
     --git "https://github.com/ElKowar/pipr" \
     --tag "$tag" \
     --root "$prefix" \
     --locked 2>/dev/null \
   || cargo install pipr \
     --git "https://github.com/ElKowar/pipr" \
     --tag "$tag" \
     --root "$prefix"; then
  ln -sf "$prefix/bin/pipr" "$BIN/pipr"
  ok "pipr -> $BIN/pipr"
  command -v bwrap >/dev/null 2>&1 \
    || warn "pipr: install bubblewrap (bwrap) for sandboxed eval, or use --no-isolation"
else
  warn "pipr: cargo install failed"
  exit 1
fi
