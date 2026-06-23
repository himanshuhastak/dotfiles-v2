#!/usr/bin/env bash
# Ensure XDG base directories exist with sane permissions (NFS/cluster homes).
set -uo pipefail
source "$(dirname "$0")/../common.sh"

_ensure_dir() {
  local dir=$1 mode=$2
  mkdir -p "$dir"
  chmod "$mode" "$dir"
  ok "$dir (mode $mode)"
}

cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"

_ensure_dir "$cfg" 700
_ensure_dir "$cache" 700
_ensure_dir "$data" 755
_ensure_dir "$state" 700
_ensure_dir "$data/fonts" 755
