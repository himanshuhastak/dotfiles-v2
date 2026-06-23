# ~/.bashrc — bash is used only to run scripts here; interactive bash hands off
# to zsh. For a full interactive bash instead, source the portable base:
#   . "$DOTFILES_DIR/config/shell/shrc"   (see ~/.bashrc.bkp archive)

[[ -f /etc/bashrc ]] && . /etc/bashrc

# Non-interactive (scripts): nothing to do. Scripts launched from the zsh
# session inherit its exported env (PATH/TOOLS_DIR). A script that must run in a
# bare environment (cron/systemd) can `. "$DOTFILES_DIR/config/shell/core/00-env.sh"`.
case $- in *i*) ;; *) return ;; esac

# Locate the repo from this stowed file (works at any clone path).
_dfself="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
_df_resolve="$(cd "$(dirname "$_dfself")/../../../config/shell" 2>/dev/null && pwd)/resolve-dotfiles-dir.sh"

DOTFILES_DIR=
# shellcheck disable=SC1090
[ -r "$_df_resolve" ] && . "$_df_resolve" "$_dfself"
# Fallback: ~/.zshenv stow symlink (when bashrc path resolution fails).
if [ ! -x "${DOTFILES_DIR:-}/var/tools/bin/zsh" ]; then
  DOTFILES_DIR=
  # shellcheck disable=SC1090
  [ -r "$_df_resolve" ] && . "$_df_resolve" "$HOME/.zshenv"
fi

# shellcheck disable=SC1090
[ -r "${DOTFILES_DIR:-}/config/shell/lib/dotfiles-zsh.sh" ] && \
  . "${DOTFILES_DIR}/config/shell/lib/dotfiles-zsh.sh"

_df_zsh=""
if type dotfiles_self_zsh_bin >/dev/null 2>&1; then
  _df_zsh="$(dotfiles_self_zsh_bin)" || true
fi
if [ -z "$_df_zsh" ] && [ -x "${DOTFILES_DIR:-}/var/tools/bin/zsh" ]; then
  _df_zsh="$DOTFILES_DIR/var/tools/bin/zsh"
fi
if [ -z "$_df_zsh" ]; then
  _df_zsh="$(command -v zsh 2>/dev/null || true)"
  [ -x "$_df_zsh" ] || _df_zsh=/usr/bin/zsh
  if [ -n "${DOTFILES_DIR:-}" ] && [ -x "$DOTFILES_DIR/var/tools/bin/zsh" ]; then
    printf 'dotfiles: using system zsh (%s); self-built exists at %s/var/tools/bin/zsh — check DOTFILES_DIR\n' \
      "$_df_zsh" "$DOTFILES_DIR" >&2
  fi
fi

if [ ! -x "$_df_zsh" ]; then
  printf '%s\n' 'dotfiles: zsh not found (install tools: ./install.sh)' >&2
  unset _dfself _df_resolve _df_zsh
  return 1
fi

# Fresh zsh login: drop bash/inherited env; pass DOTFILES_DIR so ~/.zshenv finds the repo.
_user="${USER:-$(id -un)}"
_env=( -i
  "HOME=$HOME"
  "USER=$_user"
  "LOGNAME=${LOGNAME:-$_user}"
  "TERM=${TERM:-xterm-256color}"
  "SHELL=$_df_zsh"
  "DOTFILES_DIR=${DOTFILES_DIR:-}"
)
[[ -n "${LANG:-}" ]]   && _env+=( "LANG=$LANG" )
[[ -n "${LC_ALL:-}" ]] && _env+=( "LC_ALL=$LC_ALL" )

unset _dfself _df_resolve _user
exec env "${_env[@]}" "$_df_zsh" -l
