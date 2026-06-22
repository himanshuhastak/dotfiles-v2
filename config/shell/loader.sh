# config/shell/loader.sh — the framework engine (portable: bash + zsh).
# Defines the helpers the entrypoints use to load the rest of the config.
# Sourced very early (from core/00-env.sh); must stay POSIX-ish and silent.

# _dotfiles_disabled NAME — true if NAME is in $DOTFILES_DISABLE (space list).
_dotfiles_disabled() {
  case " ${DOTFILES_DISABLE:-} " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

# _load_file FILE — source one drop-in (honouring NN- prefix + $DOTFILES_DISABLE).
# Skips unreadable files. Strips an optional NN- numeric prefix to derive the
# module name checked against $DOTFILES_DISABLE (e.g. "30-fzf.sh" → "fzf").
# Profile files have no NN- prefix; their basename is used directly ("company").
# NOTE: nothing here sets LOCAL_OPTIONS, so `setopt`s inside sourced modules
# persist globally (as intended).
_load_file() {
  local f=$1 base
  [ -r "$f" ] || return 0
  base=${f##*/}; base=${base%.*}
  case "$base" in [0-9][0-9]-*) base=${base#??-} ;; esac
  _dotfiles_disabled "$base" && return 0
  # zsh transparently loads "$f.zwc" (bytecode) instead of "$f" when it exists
  # and is newer — build it with `dotfiles compile`. bash just sources "$f".
  . "$f"
  # Wire session-state tracking (zsh only; _track_module is a no-op in bash).
  [ -n "${ZSH_VERSION:-}" ] && (( ${+functions[_track_module]} )) && _track_module "$base"
}

# _load_dir DIR [EXT]
# Source DIR/*.EXT in sorted order (EXT defaults to sh), calling _load_file on
# each. Sorted order lets numeric prefixes (00-, 30-) control load order;
# unprefixed files are order-independent. A missing or empty dir is a no-op.
_load_dir() {
  local d=$1 ext=${2:-sh} f
  [ -d "$d" ] || return 0
  if [ -n "${ZSH_VERSION:-}" ]; then
    # (N) = NULL_GLOB for THIS pattern only — an empty dir yields nothing and we
    # avoid `setopt`, which (with localoptions) would revert module option
    # changes. Wrapped in eval so bash never parses the zsh-only glob qualifier.
    eval 'for f in "$d"/*."$ext"(N); do _load_file "$f"; done'
  else
    local _ng
    _ng=$(shopt -p nullglob 2>/dev/null)
    shopt -s nullglob 2>/dev/null
    for f in "$d"/*."$ext"; do _load_file "$f"; done
    eval "${_ng:-}"
  fi
}

# _load_profile NAME — source $DOTFILES_LOCAL/profile/NAME.sh (semantic drop-in).
# Stable filenames (secrets, login, aliases, tools, company); load timing is
# fixed by the zsh entrypoints — see docs/NAMING.md. Symlinks are fine
# (e.g. company.sh -> ~/bin/gfs/company.sh outside the repo).
_load_profile() {
  local name=$1 f
  [ -n "$name" ] || return 0
  f="${DOTFILES_LOCAL}/profile/${name}.sh"
  _load_file "$f"
}

# _eval_cached NAME "CMD …" — zsh only.
# Cache the output of `eval CMD` (e.g. a tool's `init` shell snippet) and source
# the cache instead of spawning a subshell every startup. Regenerates only when
# the tool binary is newer than the cache (i.e. after an upgrade).
_eval_cached() {
  [ -n "${ZSH_VERSION:-}" ] || return 0
  local name=$1 cmd=$2 bin=${2%% *} cache
  command -v "$bin" >/dev/null 2>&1 || return 0
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/init/$name.zsh"
  if [[ ! -r "$cache" || "$(command -v "$bin")" -nt "$cache" ]]; then
    command mkdir -p "${cache:h}"
    eval "$cmd" > "$cache" 2>/dev/null
  fi
  source "$cache"
}

# _defer 'shell code string' — run the code. The default here is SYNCHRONOUS
# (plain eval) so the framework works in bash and in zsh even with deferral off.
# zsh's 90-defer module redefines this to run the code via zsh-defer, i.e. after
# the first prompt is shown (staged/async startup). Use it ONLY for non-essential,
# prompt-independent init (tool `eval "$(... init)"` hooks); never for anything
# that relies on a global `setopt`/keymap side effect (zsh-defer runs in function
# scope with LOCAL_OPTIONS, which would revert those).
_defer() { eval "$1"; }

# _init_tool_hook TOOLNAME [--defer] [--flags...]
# Initialize a tool that exports shell functions/aliases via `tool init <shell>`.
# Handles zsh/bash branching and caching transparently. Skips if tool not installed.
# Usage examples:
#   _init_tool_hook fzf --defer
#   _init_tool_hook atuin --defer --disable-up-arrow
#   _init_tool_hook starship    (no defer — prompt needs sync init)
_init_tool_hook() {
  local tool=$1 defer=0 flags=()
  shift 2>/dev/null || return 1
  
  # Extract --defer flag
  while [ $# -gt 0 ]; do
    case "$1" in
      --defer) defer=1; shift ;;
      *) flags+=("$1"); shift ;;
    esac
  done
  
  # Skip if tool not found (silent fail — tool is optional)
  if ! command -v "$tool" >/dev/null 2>&1; then
    return 0
  fi
  
  # Build the init command
  local init_cmd="$tool init"
  if [ -n "${ZSH_VERSION:-}" ]; then
    init_cmd="$init_cmd zsh"
  elif [ -n "${BASH_VERSION:-}" ]; then
    init_cmd="$init_cmd bash"
  else
    return 0
  fi
  
  # Append any flags
  if [ ${#flags[@]} -gt 0 ]; then
    init_cmd="$init_cmd ${flags[*]}"
  fi
  
  # Execute via _defer or _eval_cached, with error handling
  if [ -n "${ZSH_VERSION:-}" ]; then
    if [ $defer -eq 1 ]; then
      _defer "_eval_cached_safe '$tool' '$init_cmd'"
    else
      _eval_cached_safe "$tool" "$init_cmd"
    fi
  elif [ -n "${BASH_VERSION:-}" ]; then
    if ! eval "$($init_cmd)" 2>/dev/null; then
      : # Silent fail for bash — tool init failed but shell continues
    fi
  fi
}

# _eval_cached_safe NAME "CMD" — wrapper with error handling
_eval_cached_safe() {
  [ -n "${ZSH_VERSION:-}" ] || return 0
  local name=$1 cmd=$2 bin=${2%% *} cache
  command -v "$bin" >/dev/null 2>&1 || return 0
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/init/$name.zsh"
  
  # Generate/use cache
  if [[ ! -r "$cache" || "$(command -v "$bin")" -nt "$cache" ]]; then
    command mkdir -p "${cache:h}"
    if ! eval "$cmd" > "$cache" 2>/dev/null; then
      # Cache generation failed — fall back to direct eval
      eval "$cmd" 2>/dev/null || true
      return 0
    fi
  fi
  
  # Source cache
  if ! source "$cache" 2>/dev/null; then
    # Cache is stale or corrupt — regenerate
    if eval "$cmd" > "$cache" 2>/dev/null; then
      source "$cache" 2>/dev/null || true
    fi
  fi
}
