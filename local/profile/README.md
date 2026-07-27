# Local profile (`local/profile/`)

Tracked placeholders — **edit for your machines**. Sync dotfiles repo on **each client**
(Windows laptop, Linux workstation, etc.); `ssh.local` is the single source for tunnels.

| File | Loader | Purpose |
|------|--------|---------|
| `local.sh` | `.zshenv` | PATH, `EDITOR` |
| `login.sh` | `.zprofile` | **after ssh login** (remote): modules, optional vncstart |
| `aliases.sh` | `.zshrc` | aliases |
| `tools.sh` | `.zshrc` | tool overrides |
| `company.sh` | `.zshrc` | LSF / cluster |
| `ssh.local` | `dotfiles ssh-sync` | hosts + **LocalForward** (works from any ssh client) |
| `vnc.local` | `vncstart` | optional VNC geometry |
| `mount.lst` | `dotfiles work-stow` | `~/Work` symlinks |

**SSH tunnels:** `LocalForward` in `ssh.local` — no central script. When you `ssh res-vm-rhel`
from Windows, Linux, or Cursor, OpenSSH on **that client** sets up the forward.

- **One client, two hosts in parallel:** unique local ports per host (5902, 5903, …).
- **Two clients (PC + laptop):** both can use 5902 — each machine has its own localhost.

**Windows:** mirror `ssh.local` hosts in `C:\Users\<you>\.ssh\config` (Include chain or copy blocks).

```sh
dotfiles ssh-sync
vncpasswd && vncstart
```

`install.sh` marks `ssh.local` skip-worktree so local IP edits stay out of commits.
