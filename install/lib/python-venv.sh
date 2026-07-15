# Shared helpers for versioned Python venvs under var/tools/python/<X.Y>/.
# Sourced by install/tools/dotfiles-tools.sh and bin/dotfiles-run.
#
# Layout:
#   var/tools/python/3.12/dotfiles-tools/   # venv for that interpreter
#   var/tools/python/current -> 3.12        # active version symlink
#
# Interpreter comes from the environment only (DOTFILES_PYTHON or python3 on PATH).
# No site-specific paths or module loads.

_df_py_version() {
  # $1 = python binary → prints "3.12"
  local py=$1
  "$py" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null
}

_df_python_root() {
  echo "$1/python"
}

_df_venv_for_version() {
  # $1 = TOOLS_DIR  $2 = X.Y
  echo "$1/python/$2/dotfiles-tools"
}

_df_current_version() {
  local root="$(_df_python_root "$1")" link="$(_df_python_root "$1")/current"
  if [ -L "$link" ]; then
    basename "$(readlink "$link")"
  else
    echo ""
  fi
}

_df_set_current() {
  # $1 = TOOLS_DIR  $2 = X.Y
  local root="$(_df_python_root "$1")"
  mkdir -p "$root"
  ln -sfn "$2" "$root/current"
}

_df_resolve_venv() {
  # $1 = TOOLS_DIR → active venv path
  local tools=$1 ver venv
  ver="${DOTFILES_PYTHON_VERSION:-}"
  if [ -z "$ver" ]; then
    ver="$(_df_current_version "$tools")"
  fi
  if [ -n "$ver" ]; then
    venv="$(_df_venv_for_version "$tools" "$ver")"
    if [ -x "$venv/bin/python" ]; then
      echo "$venv"
      return 0
    fi
  fi
  return 1
}

_df_env_python() {
  # Interpreter from env only: DOTFILES_PYTHON, else python3 on PATH.
  if [ -n "${DOTFILES_PYTHON:-}" ]; then
    if [ -x "$DOTFILES_PYTHON" ]; then
      echo "$DOTFILES_PYTHON"
      return 0
    fi
    if command -v "$DOTFILES_PYTHON" >/dev/null 2>&1; then
      command -v "$DOTFILES_PYTHON"
      return 0
    fi
    return 1
  fi
  command -v python3 >/dev/null 2>&1 || return 1
  command -v python3
}
