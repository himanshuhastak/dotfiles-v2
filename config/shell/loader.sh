# config/shell/loader.sh — the framework engine (portable: bash + zsh).
# Defines the helpers the entrypoints use to load the rest of the config.
# Sourced from config/zsh/.zshenv before env.sh.

# _dotfiles_disabled NAME — true if NAME is in $DOTFILES_DISABLE (space list).
_dotfiles_disabled() {
  case " ${DOTFILES_DISABLE:-} " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

# _load_file FILE — source one module (honours $DOTFILES_DISABLE).
_load_file() {
  local f=$1 base
  [ -r "$f" ] || return 0
  base=${f##*/}; base=${base%.*}
  _dotfiles_disabled "$base" && return 0
  # zsh transparently loads "$f.zwc" (bytecode) instead of "$f" when it exists
  # and is newer — build it with `dotfiles compile`. bash just sources "$f".
  . "$f"
  # Wire session-state tracking (zsh only; _track_module is a no-op in bash).
  [ -n "${ZSH_VERSION:-}" ] && (( ${+functions[_track_module]} )) && _track_module "$base"
}

# _load_dir DIR [EXT] — source DIR/*.EXT in sorted order (unprefixed names).
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
# Stable filenames (local, aliases, company); load timing is fixed by the
# zsh entrypoints — see docs/NAMING.md. Symlinks are fine.
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
