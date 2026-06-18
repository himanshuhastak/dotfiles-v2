#!/usr/bin/env bash
# bugwarrior — sync issues from GitHub/Jira/GitLab/etc into taskwarrior.
# Python app; installed into a self-contained venv under .tools (gitignored).
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir

[ -x "$BIN/bugwarrior-pull" ] && { skip bugwarrior; exit 0; }
command -v python3 >/dev/null 2>&1 || { warn "bugwarrior: python3 required"; exit 1; }

venv="$TOOLS_DIR/venvs/bugwarrior"
log "Installing bugwarrior (python venv)"
python3 -m venv "$venv" || { warn "bugwarrior: venv creation failed"; exit 1; }
"$venv/bin/pip" install --quiet --upgrade pip >/dev/null 2>&1 || true
if "$venv/bin/pip" install --quiet bugwarrior; then
  linked=""
  for b in bugwarrior-pull bugwarrior-uda bugwarrior-vault; do
    if [ -x "$venv/bin/$b" ]; then
      ln -sf "$venv/bin/$b" "$BIN/$b"
      linked="$linked $b"
    fi
  done
  [ -n "$linked" ] || { warn "bugwarrior: no binaries in venv"; exit 1; }
  ln -sf bugwarrior-pull "$BIN/bugwarrior"
  ok "bugwarrior ->$linked bugwarrior(pull)"
else
  warn "bugwarrior: pip install failed"
  exit 1
fi
