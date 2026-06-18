# config/shell/core/00-env.sh — environment + PATH (portable: bash + zsh, login + scripts).
# Loaded by ~/.zshenv (every zsh) and ~/.shrc. Keep POSIX-ish and SILENT
# (no output) — anything printed here breaks scp/rsync/sftp non-interactive zsh.

export TERM="${TERM:-xterm-256color}"
export HOST="${HOST:-$HOSTNAME}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ---------------------------------------------------------------------------
# PATH helpers (portable indirection via eval; dedup-safe)
# ---------------------------------------------------------------------------
field_prepend() {
  local var=$1 val=$2 sep=${3:-:} cur
  eval "cur=\${$var:-}"
  case "$sep$cur$sep" in *"$sep$val$sep"*) return ;; esac
  if [ -z "$cur" ]; then eval "$var=\$val"; else eval "$var=\"\$val\$sep\$cur\""; fi
}
field_append() {
  local var=$1 val=$2 sep=${3:-:} cur
  eval "cur=\${$var:-}"
  case "$sep$cur$sep" in *"$sep$val$sep"*) return ;; esac
  if [ -z "$cur" ]; then eval "$var=\$val"; else eval "$var=\"\$cur\$sep\$val\""; fi
}
setenv()       { export "$1=$2"; }
prepend-path() { field_prepend "$1" "$2"; }
source_r()     { [ -r "$1" ] && . "$1"; }
_path_prepend() { [ -d "$1" ] && field_prepend PATH "$1"; }

# ---------------------------------------------------------------------------
# DOTFILES_DIR / TOOLS_DIR — self-owned tools tree shipped with this repo.
# (No system/NFS reuse — generated binaries live under <repo>/var/tools/bin.)
# DOTFILES_DIR is the anchor (set by the ~/.zshenv bootstrap, which derives it
# from the stow symlink, or by config/shell/shrc for bash). Everything generated
# lives under <repo>/var (the ONLY generated/downloaded tree).
# ---------------------------------------------------------------------------
: "${DOTFILES_DIR:=$HOME/dotfiles_v2}"
export DOTFILES_DIR

export TOOLS_DIR="$DOTFILES_DIR/var/tools"
export SHELDON_DATA_DIR="${SHELDON_DATA_DIR:-$DOTFILES_DIR/var/vendor}"

# Local (untracked) overrides live here: env.local, aliases.local, work.d/, conf.d/.
export DOTFILES_LOCAL="${DOTFILES_LOCAL:-$XDG_CONFIG_HOME/dotfiles.local}"

# Persisted module toggles (managed by `dotfiles disable|enable <name>`).
# One module name per line; folded into $DOTFILES_DISABLE before _load_dir runs.
if [ -r "$DOTFILES_LOCAL/disabled" ]; then
  while IFS= read -r _m; do
    case "$_m" in ''|\#*) continue ;; esac
    DOTFILES_DISABLE="${DOTFILES_DISABLE:-} $_m"
  done < "$DOTFILES_LOCAL/disabled"
  export DOTFILES_DISABLE
  unset _m
fi

export EDITOR="${EDITOR:-vim}"
export PAGER="${PAGER:-less}"

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------
_path_prepend "$TOOLS_DIR/bin"
_path_prepend "$DOTFILES_DIR/bin"
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"
export PATH

# MANPATH for our generated man pages (man dotfiles). A leading entry + the
# unset/empty case keeps a trailing-colon so the system man dirs still apply.
if [ -d "$DOTFILES_DIR/man" ]; then
  case ":${MANPATH:-}:" in
    *":$DOTFILES_DIR/man:"*) ;;
    *) MANPATH="$DOTFILES_DIR/man:${MANPATH:-}"; export MANPATH ;;
  esac
fi

# Machine env + secrets (untracked). Loaded in ALL shells (incl. scripts) so
# tools that need tokens/paths work non-interactively. Must stay silent.
source_r "$DOTFILES_LOCAL/env.local"
