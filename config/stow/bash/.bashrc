# ~/.bashrc — bash is used only to run scripts here; interactive bash hands off
# to zsh. For a full interactive bash instead, source the portable base:
#   . "$DOTFILES_DIR/config/shell/shrc"   (see ~/.bashrc.bkp archive)

[[ -f /etc/bashrc ]] && . /etc/bashrc

# Non-interactive (scripts): nothing to do. Scripts launched from the zsh
# session inherit its exported env (PATH/TOOLS_DIR). A script that must run in a
# bare environment (cron/systemd) can `. "$DOTFILES_DIR/config/shell/core/00-env.sh"`.
case $- in *i*) ;; *) return ;; esac

# Fresh zsh login: drop bash/inherited env; ~/.zshenv bootstrap rebuilds everything.
# _df="${DOTFILES_DIR:-$HOME/dotfiles_v2}"
# _zsh="$_df/var/tools/bin/zsh"
# [ -x "$_zsh" ] || _zsh="$(command -v zsh 2>/dev/null || echo /usr/bin/zsh)"
# _user="${USER:-$(id -un)}"
# 
# _env=( -i
#   "HOME=$HOME"
#   "USER=$_user"
#   "LOGNAME=${LOGNAME:-$_user}"
#   "TERM=${TERM:-xterm-256color}"
#   "SHELL=$_zsh"
# )
# [[ -n "${LANG:-}" ]] && _env+=( "LANG=$LANG" )
# [[ -n "${LC_ALL:-}" ]] && _env+=( "LC_ALL=$LC_ALL" )
# exec env "${_env[@]}" "$_zsh" -l
# exec $HOME/dotfiles-v2/var/tools/bin/zsh
