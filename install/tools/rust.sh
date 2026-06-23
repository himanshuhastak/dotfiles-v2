#!/usr/bin/env bash
# Rust toolchain — standalone tarball (static.rust-lang.org or a local file).
# Installs rustc + cargo + std only (no docs). Place rust-VER-TRIPLE.tar.xz in
# $HOME, or set RUST_TARBALL=/path/to/file.
#
#   rust.sh           install (if needed) and print versions
#   rust.sh --ensure  install only (for ensure_rust / task.sh / pipr.sh)
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

# rust_linux_triple — Rust host triple for standalone dist tarballs.
rust_linux_triple() {
  case "$(detect_arch)" in
    x86_64)  printf '%s\n' x86_64-unknown-linux-gnu ;;
    aarch64) printf '%s\n' aarch64-unknown-linux-gnu ;;
    *)       warn "rust: unsupported arch $(uname -m)"; return 1 ;;
  esac
}

# rust_stable_version — latest stable from static.rust-lang.org, else pinned fallback.
rust_stable_version() {
  local ver
  ver="$(curl -fsSL --connect-timeout 15 --max-time 45 \
    https://static.rust-lang.org/dist/channel-rust-stable.toml 2>/dev/null \
    | grep -m1 '^version = ' | sed 's/^version = "\(.*\)"/\1/')" || true
  if [ -n "$ver" ]; then
    printf '%s\n' "$ver"
    return 0
  fi
  printf '%s\n' "1.84.1"
}

# rust_find_tarball TRIPLE VERSION — locate a local rust-VER-TRIPLE.tar.xz if present.
rust_find_tarball() {
  local triple=$1 ver=$2 name="rust-${ver}-${triple}.tar.xz" p
  if [ -n "${RUST_TARBALL:-}" ] && [ -s "$RUST_TARBALL" ]; then
    printf '%s\n' "$RUST_TARBALL"; return 0
  fi
  for p in \
    "$CACHE/$name" \
    "$HOME/$name" \
    "$DOTFILES/$name" \
    "$HOME"/rust-*-"${triple}".tar.xz \
    "$DOTFILES"/rust-*-"${triple}".tar.xz; do
    [ -s "$p" ] || continue
    printf '%s\n' "$p"; return 0
  done
  return 1
}

rust_install() {
  local prefix="$TOOLS_DIR/pkg/rust" triple ver url tarball src tmpdir extract
  case ":${PATH:-}:" in *":$prefix/bin:"*) ;; *)
    PATH="$prefix/bin:${PATH:-}"; export PATH ;;
  esac
  if command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
    return 0
  fi
  if [ -x "$prefix/bin/rustc" ] && [ -x "$prefix/bin/cargo" ]; then
    return 0
  fi
  if [ -d "$prefix" ]; then
    warn "rust: removing incomplete install at $prefix"
    rm -rf "$prefix"
  fi
  triple="$(rust_linux_triple)" || return 1
  ver="$(rust_stable_version)"
  url="https://static.rust-lang.org/dist/rust-${ver}-${triple}.tar.xz"
  tarball="$CACHE/rust-${ver}-${triple}.tar.xz"
  mkdir -p "$CACHE" "$prefix"
  if src="$(rust_find_tarball "$triple" "$ver")"; then
    if [ "$src" != "$tarball" ]; then
      log "Using local Rust tarball: $src"
      cp -f "$src" "$tarball"
    else
      skip "rust ${ver} tarball (cached at $tarball)"
    fi
  elif [ ! -s "$tarball" ]; then
    command -v curl >/dev/null 2>&1 || {
      warn "rust: no local tarball and curl unavailable"
      warn "  place rust-${ver}-${triple}.tar.xz in \$HOME or set RUST_TARBALL=/path/to/file"
      return 1
    }
    log "Downloading Rust ${ver} (${triple}) — large tarball, may take a few minutes"
    log "  $url"
    curl -fL --retry 3 --connect-timeout 30 --max-time 900 -o "$tarball" "$url" \
      || { warn "rust: download failed: $url"; return 1; }
  else
    skip "rust ${ver} tarball (cached at $tarball)"
  fi
  tmpdir="$(mktemp -d "$CACHE/rust-install.XXXXXX")"
  log "Installing Rust ${ver} -> $prefix (rustc + cargo + std only; skipping docs)"
  (
    cd "$tmpdir"
    tar -xJf "$tarball"
    extract="$(find . -maxdepth 1 -mindepth 1 -type d | head -n1)"
    [ -n "$extract" ] && [ -x "$extract/install.sh" ] || exit 1
    cd "$extract"
    ./install.sh --prefix="$prefix" --disable-ldconfig \
      --components="rustc,cargo,rust-std-${triple}"
  ) || { rm -rf "$tmpdir" 2>/dev/null || true; warn "rust: install.sh failed"; return 1; }
  rm -rf "$tmpdir" 2>/dev/null || true
  [ -x "$prefix/bin/rustc" ] && [ -x "$prefix/bin/cargo" ] \
    || { warn "rust: rustc/cargo missing after install"; return 1; }
  ok "rust ${ver} -> $prefix/bin"
}

case "${1:-}" in
  --ensure)
    rust_install
    ;;
  *)
    rust_install
    rustc --version
    cargo --version
    ;;
esac
