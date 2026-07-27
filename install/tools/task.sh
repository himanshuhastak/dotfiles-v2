#!/usr/bin/env bash
# taskwarrior (task) — built from source (no prebuilt static binary exists).
# taskwarrior 3.x needs Rust/cargo (TaskChampion via corrosion), cxxbridge-cmd
# on PATH (must match the cxx version in task's Cargo.lock), plus cmake and C++17.
# Opt-in: not part of the default install order.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

# cxx version from task's Cargo.lock (corrosion requires cxxbridge-cmd to match exactly).
_task_cxx_version() {
  local tag=$1 ver lock
  ver="${tag#v}"
  lock="$(curl -fsSL --connect-timeout 15 --max-time 45 \
    "https://raw.githubusercontent.com/GothenburgBitFactory/taskwarrior/${tag}/src/taskchampion-cpp/Cargo.lock" \
    2>/dev/null)" || lock="$(curl -fsSL --connect-timeout 15 --max-time 45 \
      "https://raw.githubusercontent.com/GothenburgBitFactory/taskwarrior/v${ver}/src/taskchampion-cpp/Cargo.lock" \
      2>/dev/null)" || true
  if [ -n "$lock" ]; then
    printf '%s\n' "$lock" | awk '
      /^name = "cxx"$/ { getline; sub(/^version = "/, ""); sub(/"$/, ""); print; exit }
    '
    return 0
  fi
  # Fallback when GitHub is unreachable (task 3.4.2 lockfile).
  case "$ver" in 3.4.*) printf '%s\n' "1.0.144" ;; *) return 1 ;; esac
}

# corrosion looks for `cxxbridge` on PATH; install cxxbridge-cmd at the matching version.
ensure_task_cxxbridge() {
  local root="$TOOLS_DIR/pkg/cargo-tools" tag cxx_ver
  case ":${PATH:-}:" in *":$root/bin:"*) ;; *)
    PATH="$root/bin:${PATH:-}"
    export PATH
    ;;
  esac
  command -v cxxbridge >/dev/null 2>&1 && return 0

  tag="$(gh_latest_tag GothenburgBitFactory/taskwarrior)" || tag="v3.4.2"
  cxx_ver="$(_task_cxx_version "$tag")" || {
    warn "task: cannot determine cxx version for $tag"
    return 1
  }

  ensure_rust || return 1
  export CARGO_HOME="${CARGO_HOME:-$TOOLS_DIR/cargo-home}"
  mkdir -p "$CARGO_HOME" "$root"
  log "Installing cxxbridge-cmd $cxx_ver (must match cxx in task $tag)"
  if ! cargo install cxxbridge-cmd --version "$cxx_ver" --root "$root"; then
    warn "task: cxxbridge-cmd install failed (needs crates.io network)"
    warn "  offline: cargo install cxxbridge-cmd --version $cxx_ver --root $root"
    warn "  then ensure $root/bin is on PATH before building"
    return 1
  fi
  command -v cxxbridge >/dev/null 2>&1 ||
    {
      warn "task: cxxbridge missing after cargo install"
      return 1
    }
  ok "cxxbridge $cxx_ver -> $root/bin/cxxbridge"
}

ensure_rust || exit 1
ensure_task_cxxbridge || exit 1
build_from_source task GothenburgBitFactory/taskwarrior 'task-{ver}.tar.gz' task
