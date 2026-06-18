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

# _load_dir DIR [EXT]
# Source DIR/*.EXT in sorted order (EXT defaults to sh). Each file:
#   - is skipped if unreadable or if its basename (minus an NN- prefix and
#     extension) appears in $DOTFILES_DISABLE.
# Sorted order lets numeric prefixes (00-, 30-) control load order; unprefixed
# files are order-independent. nullglob is handled per-shell so an empty dir is
# a no-op rather than sourcing a literal glob.
# _load_file FILE — source one drop-in (honouring NN- prefix + $DOTFILES_DISABLE).
# Kept separate from _load_dir so the loop body is shared between the zsh and
# bash globbing branches. NOTE: nothing here sets LOCAL_OPTIONS, so `setopt`s
# inside the sourced modules persist globally (as intended).
_load_file() {
  local f=$1 base
  [ -r "$f" ] || return 0
  base=${f##*/}; base=${base%.*}
  case "$base" in [0-9][0-9]-*) base=${base#??-} ;; esac
  _dotfiles_disabled "$base" && return 0
  # zsh transparently loads "$f.zwc" (bytecode) instead of "$f" when it exists
  # and is newer — build it with `dotfiles compile`. bash just sources "$f".
  . "$f"
}

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

# _load_local LO HI — source $DOTFILES_LOCAL/NN-*.sh where NN (00–99) is in [LO, HI].
# Flat per-user drop-ins; number sets load phase (see docs/NAMING.md).
_load_local() {
  local lo=$1 hi=$2 d="${DOTFILES_LOCAL:-}" f base nn
  [ -d "$d" ] || return 0
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval 'for f in "$d"/[0-9][0-9]-*.sh(N); do
      base=${f##*/}; nn=${base%%-*}
      [ "$nn" -ge "'"$lo"'" ] && [ "$nn" -le "'"$hi"'" ] || continue
      _load_file "$f"
    done'
  else
    local _ng
    _ng=$(shopt -p nullglob 2>/dev/null)
    shopt -s nullglob 2>/dev/null
    for f in "$d"/[0-9][0-9]-*.sh; do
      base=${f##*/}; nn=${base%%-*}
      [ "$nn" -ge "$lo" ] && [ "$nn" -le "$hi" ] || continue
      _load_file "$f"
    done
    eval "${_ng:-}"
  fi
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
