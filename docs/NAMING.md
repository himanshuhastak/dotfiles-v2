# Naming & conventions

## Module files (framework)

- **`NN-name.ext`** — a leading two-digit prefix controls load order within a
  directory (`_load_dir` sorts lexically). Unprefixed files are order-independent.
- **`.sh`** — portable (bash + zsh). Must avoid bash-only and zsh-only syntax.
  Lives in `core/` and `conf.d/`.
- **`.zsh`** — zsh-only. Lives in `config/shell/zsh/`.
- The **module name** (for `dotfiles disable`) is the filename minus the `NN-`
  prefix and extension: `30-fzf.sh` → `fzf`, `20-completion.zsh` → `completion`.

## Suggested number ranges (zsh modules)

| Range | Use |
|---|---|
| 00–09 | options, builtin modules, colors (no external deps) |
| 10–19 | history and other core interactive setup |
| 20–29 | completion system (compinit) |
| 30–49 | UI/nav (term title, dir hashes, autoloaded functions) |
| 50–89 | maintenance / conditional hooks (unused range ok) |
| 90–95 | deferral backend, then plugins |
| 96–99 | keybindings that depend on plugins |

## conf.d (per-tool drop-ins)

- One file per tool. Guard with `command -v <tool> >/dev/null 2>&1 || return 0`.
- Defer expensive `eval "$(tool init)"` with `_defer 'eval "$(tool init zsh)"'`.
- Never defer the prompt (`starship`) or anything needing a global `setopt`.

## Toggles

- `dotfiles disable <name>` appends `name` to `$DOTFILES_LOCAL/disabled`.
- `00-env.sh` folds that file into `$DOTFILES_DISABLE`; `_load_file` skips matching
  modules. `dotfiles enable <name>` removes it. Re-`reload` to apply.
- For profile files, `<name>` is the basename without `.sh` (e.g. `company`).

## Local profile (`$DOTFILES_DIR/local/profile/`)

`$DOTFILES_LOCAL` defaults to `$DOTFILES_DIR/local`. Per-user config lives in
`$DOTFILES_LOCAL/profile/` (gitignored; create files as needed).

Profiles are one folder, **several file kinds** — not everything is a `.sh` sourced
by zsh. Each kind has its own “loader”:

| File | Kind | Applied by | When | Use for |
|------|------|------------|------|---------|
| `local.sh` | shell | `_load_profile` in `.zshenv` | every zsh | PATH, `EDITOR`, machine env (**no tokens**) |
| `login.sh` | shell | `_load_profile` in `.zprofile` | **SSH login** (remote) | modules, optional `vncstart`, post-login setup |
| `aliases.sh` | shell | `_load_profile` in `.zshrc` | interactive | personal aliases |
| `tools.sh` | shell | `_load_profile` in `.zshrc` | interactive | tool overrides |
| `company.sh` | shell | `_load_profile` in `.zshrc` (last) | interactive | LSF / cluster / work env |
| `ssh.local` | OpenSSH | `dotfiles ssh-sync` | login `--if-needed` | hosts, `HostName`, `LocalForward`, `ProxyJump` |
| `vnc.local` | shell snippet | `vncstart` | when you start VNC | optional `VNC_GEOMETRY` |
| `mount.lst` | data | `dotfiles work-stow` | login `--if-needed` | `path:shortname` → `~/Work/` |

**Secrets (tokens):** `dotfiles secrets` (OS keyring) — **never** `profile/secrets.sh`
or API keys in any profile file. `dotfiles doctor` warns if `secrets.sh` exists.

**Why `ssh.local` is not a `.sh` profile:** `ssh` reads `~/.ssh/config` at connect
time. It does not run your shell. `ssh-sync` symlinks `ssh.local` →
`~/.ssh/config.d/local.conf` so OpenSSH can `Include` it.

**Toggle shell profiles:** `dotfiles disable company` skips `company.sh` only.
Non-shell files (`ssh.local`, `mount.lst`) are not affected by disable.

### Shell profile load order (zsh)

```text
.zshenv     → local.sh
.zprofile   → stow / work-stow / ssh-sync --if-needed → login.sh
.zshrc      → aliases → … modules … → tools.sh → company.sh
```

### OpenSSH load order (`~/.ssh/config`)

```text
config.d/local.conf   ← symlink to local/profile/ssh.local
Host github.com / gitlab.com
config.d/dotfiles.conf ← Host * defaults (in repo)
```

```sh
mkdir -p local/profile
cp tools/examples/local.sh.example local/profile/local.sh
cp tools/examples/ssh.local.example local/profile/ssh.local
dotfiles ssh-sync
dotfiles secrets set jira_api_token
exec zsh
```

`local/disabled` — module toggles (`dotfiles disable`); created automatically.

### Work machines (optional)

```sh
printf '/scratch/$USER:scratch\n/tmp:tmp\n' > local/profile/mount.lst
# edit local/profile/company.sh for your cluster modules
dotfiles work-stow
```

Generated work-stow symlinks live in `var/work/` (not `local/` or `config/stow/`).
`dotfiles sync` excludes `local/profile/*` and `local/disabled`.

## Host-specific tweaks (outside the repo)

| Path | Purpose |
|---|---|
| `~/.zshrc.$USER` | host/user-specific zsh tweaks |
| `~/.zprofile.$USER` | host/user-specific login tweaks |

Override the local root with `export DOTFILES_LOCAL=/path/to/other` if needed.

### Bash → zsh handoff (`~/.bashrc`)

Interactive bash execs a clean `env -i` login zsh via `config/shell/lib/bash-zsh-handoff.sh`.
X11 (`DISPLAY`, `XAUTHORITY`, cookies) is handled in `.zprofile` on every login shell.

| `DOTFILES_ZSH_LOGIN` | Handoff | `.zprofile` |
|---|---|---|
| `1` / `yes` / unset (default) | `zsh -l` | runs |
| `0` / `no` / `nonlogin` | `zsh` | skipped |

```sh
# non-login handoff for one session (or set in local/profile/local.sh)
export DOTFILES_ZSH_LOGIN=0
```
