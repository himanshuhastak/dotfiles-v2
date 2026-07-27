#!/usr/bin/env bash
# Install CLIs via aqua (aqua.yaml), then legacy scripts for tools aqua cannot ship.
# Fonts stay in nerdfonts/ and are handled by install-fonts.sh (not re-downloaded).
set -uo pipefail

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPTS/../.." && pwd)"
# shellcheck source=../common.sh
source "$DOTFILES/install/common.sh"

WITH_OPTIONAL=0
SEQUENTIAL=0 # kept for flag compat; aqua parallelizes internally
LEGACY_ONLY=0
AQUA_ONLY=0
EXTRA_AQUA_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --with-optional | --with-optional-tools)
      WITH_OPTIONAL=1
      shift
      ;;
    --sequential)
      SEQUENTIAL=1
      shift
      ;; # no-op for aqua path
    --legacy-only)
      LEGACY_ONLY=1
      shift
      ;;
    --aqua-only)
      AQUA_ONLY=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      warn "install-tools: unknown flag $1 (ignored)"
      shift
      ;;
    *)
      EXTRA_AQUA_ARGS+=("$1")
      shift
      ;;
  esac
done

export AQUA_ROOT_DIR="${AQUA_ROOT_DIR:-$DOTFILES/var/tools/aqua}"
# Prefer GitHub token when present (rate limits)
export AQUA_GITHUB_TOKEN="${AQUA_GITHUB_TOKEN:-${GITHUB_TOKEN:-}}"

init_tools_dir
case ":$PATH:" in *":$AQUA_ROOT_DIR/bin:"*) ;; *)
  PATH="$AQUA_ROOT_DIR/bin:$PATH"
  export PATH
  ;;
esac

run_aqua() {
  local aqua_bin
  # ensure-aqua logs to stderr; stdout is only the binary path.
  aqua_bin="$(bash "$DOTFILES/install/bin/ensure-aqua.sh")" || return 1
  aqua_bin="${aqua_bin##*$'\n'}" # last line only, if anything leaked
  [ -x "$aqua_bin" ] || aqua_bin="$AQUA_ROOT_DIR/bin/aqua"
  [ -x "$aqua_bin" ] || {
    warn "aqua missing at $AQUA_ROOT_DIR/bin/aqua"
    return 1
  }

  # aqua installs packages concurrently (Go goroutines). Legacy scripts below
  # stay sequential — there are only a handful left.
  log "aqua install -c aqua.yaml --exclude-tags optional"
  (
    cd "$DOTFILES"
    AQUA_ROOT_DIR="$AQUA_ROOT_DIR" \
      "$aqua_bin" -c "$DOTFILES/aqua.yaml" install --exclude-tags optional "${EXTRA_AQUA_ARGS[@]}"
  ) || return 1
  if [ "$WITH_OPTIONAL" -eq 1 ]; then
    log "aqua install -c aqua.yaml -t optional"
    (
      cd "$DOTFILES"
      AQUA_ROOT_DIR="$AQUA_ROOT_DIR" \
        "$aqua_bin" -c "$DOTFILES/aqua.yaml" install -t optional
    ) || return 1
  fi
  return 0
}

# Tools not in aqua-registry (or source/pip builds).
LEGACY_CORE=(chezmoi broot zsh)
LEGACY_OPTIONAL=(rust bash blesh parallel task timew oc-rsync pipr bugwarrior)
# always-available helpers still needed by the framework/CLI
LEGACY_HELPERS=(betterleaks zshellcheck dotfiles-tools)

run_legacy() {
  local list=("$@") t script failed=""
  local tools="$DOTFILES/install/tools"
  for t in "${list[@]}"; do
    script="$tools/$t.sh"
    if [ ! -f "$script" ]; then
      warn "no legacy installer for '$t'"
      failed="$failed $t"
      continue
    fi
    bash "$script" || failed="$failed $t"
  done
  [ -z "$failed" ] || {
    warn "legacy failed:$failed"
    return 1
  }
  return 0
}

rc=0
if [ "$LEGACY_ONLY" -eq 0 ]; then
  run_aqua || rc=1
fi

if [ "$AQUA_ONLY" -eq 0 ]; then
  run_legacy "${LEGACY_CORE[@]}" "${LEGACY_HELPERS[@]}" || rc=1
  if [ "$WITH_OPTIONAL" -eq 1 ]; then
    run_legacy "${LEGACY_OPTIONAL[@]}" || rc=1
  fi
fi

# Symlink selected aqua bins into var/tools/bin for hardcoders — never chezmoi
# (must stay musl from install/tools/chezmoi.sh on RHEL 8 / old glibc).
if [ -d "$AQUA_ROOT_DIR/bin" ]; then
  mkdir -p "$BIN"
  for b in sheldon fzf atuin zoxide direnv starship bat delta eza fd rg jq yq zellij; do
    if [ -e "$AQUA_ROOT_DIR/bin/$b" ] && [ ! -e "$BIN/$b" ]; then
      ln -sfn "$AQUA_ROOT_DIR/bin/$b" "$BIN/$b" 2>/dev/null || true
    fi
  done
fi

[ "$SEQUENTIAL" -eq 1 ] && true # silence unused
exit "$rc"
