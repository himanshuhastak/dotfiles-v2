#!/usr/bin/env bash
# Back-compat wrapper — use fetch-themes.sh
exec bash "$(dirname "$0")/fetch-themes.sh" "$@"
