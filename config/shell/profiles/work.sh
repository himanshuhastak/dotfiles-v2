# config/shell/profiles/work.sh — interactive work-profile loader.
# Loads ONE company profile so the same machine can switch employers/clients.
# Profiles are untracked and live under $DOTFILES_LOCAL/work.d/<name>.sh.
#
# Selection order:
#   1. $WORK_PROFILE        (export it from env.local to pin a machine)
#   2. $DOTFILES_LOCAL/work.active   (a file containing the profile name)
#   3. $DOTFILES_LOCAL/work.sh       (a single, unnamed profile)
#
# Loaded only in interactive shells (from ~/.zshrc), so work env is NOT visible
# to bash scripts. If a script needs a work var, export it from env.local
# instead. Keep profiles silent.

_work_dir="${DOTFILES_LOCAL:-$XDG_CONFIG_HOME/dotfiles.local}/work.d"
_work_name="${WORK_PROFILE:-}"

if [ -z "$_work_name" ] && [ -r "${DOTFILES_LOCAL}/work.active" ]; then
  _work_name="$(head -n1 "${DOTFILES_LOCAL}/work.active" 2>/dev/null | tr -d '[:space:]')"
fi

if [ -n "$_work_name" ] && [ -r "$_work_dir/$_work_name.sh" ]; then
  . "$_work_dir/$_work_name.sh"
elif [ -r "${DOTFILES_LOCAL}/work.sh" ]; then
  . "${DOTFILES_LOCAL}/work.sh"
fi

unset _work_dir _work_name
