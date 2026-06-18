#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
# mvdan/sh ships shfmt as a single raw binary (no archive).
install_tool shfmt mvdan/sh 'shfmt_{tag}_linux_{goarch}' shfmt
