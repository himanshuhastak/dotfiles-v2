#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool yq mikefarah/yq 'yq_linux_{goarch}'
