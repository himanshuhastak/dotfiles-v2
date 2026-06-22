#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool duf muesli/duf 'duf_{ver}_linux_{arch}.tar.gz'
