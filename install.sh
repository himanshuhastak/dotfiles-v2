#!/usr/bin/env bash
# Bootstrap entrypoint — runs the full setup.
# Steps live in install/steps/*.sh ; per-tool installers in install/tools/*.sh
exec bash "$(dirname "$0")/install/bootstrap.sh" "$@"
