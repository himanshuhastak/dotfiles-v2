# Post-SSH login hook (remote side only).
# Runs when you: ssh host  (interactive login shell)
# Does NOT run for: scp, ssh host 'cmd', non-login Cursor channels, rsync.
#
# Loaded from .zprofile after dotfiles stow / work-stow / ssh-sync.
# SSH tunnels: ssh.local (LocalForward). This file: remote setup after you land.

# --- cluster / modules (examples) ---
# source /etc/profile.d/res.sh
# module load lsf

# --- optional: start VNC if not already up (display :2 → port 5902) ---
# if command -v vncstart >/dev/null 2>&1; then
#   vncserver -list 2>/dev/null | grep -q ':2' || vncstart
# fi

# --- optional: only when SSH (not local console / LSF) ---
# if [[ -n ${SSH_CONNECTION:-}${SSH_CLIENT:-} ]]; then
#   : # e.g. echo "SSH from ${SSH_CLIENT%% *}"
# fi
