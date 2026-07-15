#!/usr/bin/env bash
# actionlint (rhysd/actionlint) — linter for GitHub Actions workflow YAML.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool actionlint rhysd/actionlint 'actionlint_{ver}_linux_{goarch}.tar.gz' actionlint
