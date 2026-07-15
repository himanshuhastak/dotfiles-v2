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
`$DOTFILES_LOCAL/profile/*.sh` (gitignored; create files as needed).

| File | Loaded from | Use for |
|---|---|---|
| `local.sh` | `.zshenv` / `00-env.sh` | every shell — PATH, machine env (**no tokens**) |
| `aliases.sh` | `.zshrc` (early) | interactive aliases |
| `company.sh` | `.zshrc` (last) | work / cluster env (optional) |
| `login.sh` | `.zprofile` | login-only setup |
| `mount.lst` | `dotfiles work-stow` | `path:shortname` lines for `~/Work/` |

**API tokens:** `dotfiles secrets` (OS keyring) — not shell profile files.
Legacy `secrets.sh` is **not** loaded; `dotfiles doctor` warns if it still exists.

```sh
mkdir -p local/profile
cp tools/examples/local.sh.example local/profile/local.sh
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
