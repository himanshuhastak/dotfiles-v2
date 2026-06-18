# work profile example — copy to $DOTFILES_LOCAL/work.d/<company>.sh
# ($DOTFILES_LOCAL defaults to ~/.config/dotfiles.local), then either:
#   echo <company> > ~/.config/dotfiles.local/work.active
# or in ~/.config/dotfiles.local/env.local:
#   export WORK_PROFILE=<company>
#
# These files are gitignored / never tracked. Keep them SILENT (no echo) and
# put secrets in env.local, not here.

# --- exports (paths, hosts; loaded only in interactive shells) ---
# export WORK_ROOT="$HOME/work/<company>"
# export GIT_HOST="git.company.internal"
# _path_prepend "/opt/company/bin"; export PATH

# --- functions ---
# work-vpn()  { sudo openconnect vpn.company.internal; }
# work-ssh()  { ssh bastion.company.internal "$@"; }

# --- aliases ---
# alias k='kubectl -n company-dev'
# alias dstg='deploy --env staging'
