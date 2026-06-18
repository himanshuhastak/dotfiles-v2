#!/usr/bin/env bash
# timewarrior (timew) — built from source (no prebuilt static binary exists).
# Needs cmake + make + a C++17 compiler. Opt-in: not in the default order.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
build_from_source timew GothenburgBitFactory/timewarrior 'timew-{ver}.tar.gz' timew
