#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
# koalaman/shellcheck ships a static binary inside shellcheck-<tag>/.
install_tool shellcheck koalaman/shellcheck 'shellcheck-{tag}.linux.{arch}.tar.xz' shellcheck
