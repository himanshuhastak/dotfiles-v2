# Structure

## Directory layout

```
dotfiles_v2/
  local/                      gitignored per-user overrides (only profile/.gitignore tracked)
  install.sh                  thin wrapper -> install/bootstrap.sh
  bin/dotfiles                management CLI (on PATH via $DOTFILES_DIR/bin)
  Makefile                    convenience targets (wrap the CLI)
  config/
    zsh/                      $ZDOTDIR: .zshenv, .zprofile, .zshrc — in-repo zsh config
    stow/                     GNU-stow packages -> symlinked into $HOME
      home/.zshenv            the ONLY zsh file in $HOME (ZDOTDIR bootstrap)
      bash/ git/ atuin/ sheldon/ starship/ task/ bat/ lazygit/
      ssh/ vnc/             optional: ~/.ssh snippets, ~/.vnc templates (conditional stow)
      zellij/                 config.kdl + layouts/ + plugins/ (symlinks → var/vendor)
    shell/                    the framework engine (sourced, never stowed)
      loader.sh               _load_dir/_load_file/_load_profile/_eval_cached/_defer
      shrc                    portable base for an interactive bash fallback
      core/                   00-env 10-functions 20-aliases (bash + zsh)
      zsh/                    zsh-only modules, numbered by load order
      conf.d/                 per-tool drop-ins (fzf, atuin, zoxide, starship, …)
      completions/            extra _foo completion functions (on fpath)
      functions/              autoloaded zsh functions (one per file)
  install/                    the installer
    bootstrap.sh common.sh cleanup.sh
    bin/ (stow)  steps/  tools/
  test/                       bats smoke tests
  tools/                      productivity (dotfiles_tools Python package)
  docs/  man/                 documentation + generated man page
  var/                        GENERATED, gitignored: tools/ vendor/ cache/
```

**CLI surface**

| Command | Role |
|---------|------|
| `dotfiles` | shell/env: stow, doctor, check, bench, … |
| `dotfiles jira\|gitlab\|secrets\|bugwarrior\|invite` | productivity (one venv: `dotfiles-run`) |

Productivity dispatch: `bin/dotfiles` → `bin/dotfiles-run` → `python -m dotfiles_tools <cmd>`.
## ZDOTDIR

`~/.zshenv` (stow package `home`) is the only zsh file in `$HOME`. At startup it:

1. resolves its own real path (through the stow symlink) to locate `$DOTFILES_DIR`;
2. exports `ZDOTDIR="$DOTFILES_DIR/config/zsh"`;
3. sources `$ZDOTDIR/.zshenv`.

zsh then reads the rest of its startup files (`.zprofile`, `.zshrc`, `.zlogin`)
from `$ZDOTDIR` automatically. Result: `$HOME` stays clean and there are no
per-file zsh symlinks.

## Startup / load order

`.zshenv` (every zsh): `loader.sh` → `core/00-env.sh` → `profile/local.sh`
(optional).

`.zprofile` (login only): `dotfiles stow --if-needed` → `dotfiles work-stow
--if-needed` → `profile/login.sh` → `~/.zprofile.$USER`.

Stow self-heal runs **only on login** (no deferred non-login heal).

`.zshrc` (interactive): `core/10-functions.sh` → `core/20-aliases.sh` →
`profile/aliases.sh` → `config/shell/zsh/*` → `conf.d/*` → `profile/tools.sh` →
`profile/company.sh`.

zsh modules load in this order:

| # | module | role |
|---|---|---|
| 00 | options | setopts + emacs keymap |
| 02 | zmodload | builtin modules (datetime/terminfo/complist) |
| 04 | colors | LS_COLORS + zsh color arrays |
| 05 | directories | AUTO_PUSHD + dir-stack jumps |
| 10 | history | history options |
| 20 | completion | fpath + compinit + grml-grade zstyles |
| 30 | termsupport | terminal title hooks |
| 40 | hashdirs | `hash -d` named dirs (`~dot`) |
| 45 | functions | autoload `functions/` |
| 90 | defer | source zsh-defer; upgrade `_defer` to async |
| 95 | plugins | sheldon (`syntax-highlighting` last) |
| 99 | keybindings | history-substring-search, edit-command-line |

## Async loading

`90-defer.zsh` sources zsh-defer (from `var/vendor/zsh-defer`) and redefines
`_defer 'code'` to run `code` after the first prompt. The `conf.d` tool hooks
(`fzf`, `atuin`, `zoxide`, `direnv`, `broot`) use `_defer`, so the prompt appears
instantly and they finish wiring up a few ms later. `starship` (the prompt) and
anything relying on a global `setopt`/keymap are **not** deferred — zsh-defer
runs in function scope with `LOCAL_OPTIONS`, which would revert such changes.

If zsh-defer is missing or the `defer` module is disabled, `_defer` falls back to
synchronous `eval` (defined in `loader.sh`), so nothing breaks.

## The `var/` invariant

Everything under `var/` is generated/downloaded and gitignored:

- `var/tools/` — self-installed CLI binaries (on PATH first) plus versioned
  Python venvs: `var/tools/python/<X.Y>/dotfiles-tools/` with
  `var/tools/python/current` → active version.
- `var/vendor/` — cloned zsh plugins, zsh-defer, Zellij WASM plugins (`zellij-plugins/`).
- `var/cache/` — installer scratch.
- `var/work/` — generated work-stow package for `~/Work` mount links.

Durable shell state (zcompdump, init caches, history) lives under XDG
(`~/.cache`, `~/.local/state`), **not** in `var/`. To reinstall cleanly:
`rm -rf var && ./install.sh`.

## Local profile (`local/profile/`)

Per-user config in `local/profile/` — **tracked placeholder files** (edit for your
machines). Only `secrets.sh` is gitignored. See `local/profile/README.md`.

| File | When loaded | Typical contents |
|---|---|---|
| `local.sh` | every shell (via `.zshenv`) | PATH, machine env — **no API tokens** |
| `aliases.sh` | interactive zsh (early `.zshrc`) | personal aliases |
| `company.sh` | interactive zsh (last) | work / LSF / cluster env (optional) |
| `login.sh` | login `.zprofile` | login-only setup |
| `mount.lst` | `dotfiles work-stow` | disk shortcuts into `~/Work/` (optional) |

**Tokens:** `dotfiles secrets` (OS keyring). Legacy `secrets.sh` is not loaded.
Instance settings: `local/tools/config.toml`. See [PRODUCTIVITY.md](PRODUCTIVITY.md).

## ~/Work mounts (`local/profile/mount.lst` → `var/work/` → `~/Work/`)

`path:shortname` lines in `local/profile/mount.lst` (e.g. `/scratch/$USER:scratch`).

```sh
dotfiles work-stow
```

This generates a stow package under **`var/work/`** (not `local/work/`, not
`config/stow/`). `config/stow/` holds tracked dotfiles shared across machines;
`var/work/` is regenerated per host from your `mount.lst`.
