#!/usr/bin/env bash
# dotfiles-tools — venv at var/tools/python/<X.Y>/dotfiles-tools
#
# Uses the environment Python only:
#   DOTFILES_PYTHON=/path/to/python3   (optional override)
#   otherwise: python3 on PATH
#
# Put python3 on PATH (or set DOTFILES_PYTHON) before running update-tools.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
source "$(dirname "$0")/../lib/python-venv.sh"
init_tools_dir

PY="$(_df_env_python)" || {
  warn "dotfiles-tools: no python3 on PATH (set DOTFILES_PYTHON or load your toolchain)"
  exit 1
}

PY_VER="$(_df_py_version "$PY")" || {
  warn "dotfiles-tools: cannot read version from $PY"
  exit 1
}

venv="$(_df_venv_for_version "$TOOLS_DIR" "$PY_VER")"
_bin="$venv/bin"

_link_bins() {
  for b in bugwarrior-pull bugwarrior-uda bugwarrior-vault; do
    [ -x "$_bin/$b" ] && ln -sf "$_bin/$b" "$BIN/$b"
  done
  [ -x "$BIN/bugwarrior-pull" ] && ln -sf bugwarrior-pull "$BIN/bugwarrior" 2>/dev/null || true
}

_venv_ok() {
  [ -x "$_bin/python" ] || return 1
  "$_bin/python" -c 'import yaml, gitlab, jira, keyring, toml, bugwarrior' 2>/dev/null
}

# Remove legacy flat path from earlier layouts.
legacy="$TOOLS_DIR/venvs/dotfiles-tools"
if [ -d "$legacy" ]; then
  log "Removing legacy venv $legacy (now under python/<ver>/)"
  rm -rf "$legacy"
fi

if _venv_ok; then
  _df_set_current "$TOOLS_DIR" "$PY_VER"
  skip "dotfiles-tools (python/$PY_VER via $PY)"
  _link_bins
  exit 0
fi

log "Installing dotfiles-tools → python/$PY_VER  ($PY)"
mkdir -p "$(dirname "$venv")"
rm -rf "$venv"
"$PY" -m venv "$venv" || {
  warn "dotfiles-tools: venv creation failed"
  exit 1
}
"$_bin/pip" install --quiet --upgrade pip setuptools wheel >/dev/null 2>&1 || true

if "$_bin/pip" install --quiet \
  'pyyaml>=6' \
  'python-gitlab>=4' \
  'jira>=3' \
  'keyring>=24' \
  'toml>=0.10' \
  'bugwarrior[keyring]>=1.8'; then
  _df_set_current "$TOOLS_DIR" "$PY_VER"
  ok "dotfiles-tools -> $venv ($("$PY" -V 2>&1))"
  _link_bins
else
  warn "dotfiles-tools: pip install failed"
  exit 1
fi
