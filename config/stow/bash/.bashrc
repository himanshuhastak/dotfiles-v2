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
_dfroot="$(cd "$(dirname "$_dfself")/../../.." && pwd)"
. "$_dfroot/config/shell/resolve-dotfiles-dir.sh" "$_dfself"

# Prefer self-installed zsh; fall back to system zsh.
_zsh="$DOTFILES_DIR/var/tools/bin/zsh"
[ -x "$_zsh" ] || _zsh="$(command -v zsh 2>/dev/null || true)"
[ -x "$_zsh" ] || _zsh=/usr/bin/zsh
if [ ! -x "$_zsh" ]; then
  printf '%s\n' 'dotfiles: zsh not found (install tools: ./install.sh)' >&2
  unset _dfself _dfroot _zsh
  return 1
fi

# Fresh zsh login: drop bash/inherited env; ~/.zshenv bootstrap rebuilds everything.
_user="${USER:-$(id -un)}"
_env=( -i
  "HOME=$HOME"
  "USER=$_user"
  "LOGNAME=${LOGNAME:-$_user}"
  "TERM=${TERM:-xterm-256color}"
  "SHELL=$_zsh"
)
[[ -n "${LANG:-}" ]]   && _env+=( "LANG=$LANG" )
[[ -n "${LC_ALL:-}" ]] && _env+=( "LC_ALL=$LC_ALL" )

unset _dfself _dfroot _user
exec env "${_env[@]}" "$_zsh" -l
