# Structure

## Directory layout

```
dotfiles_v2/
  local/                      profile dirs + tracked template local/example/
  install.sh                  thin wrapper -> install/bootstrap.sh
  bin/dotfiles                management CLI (on PATH via $DOTFILES_DIR/bin)
  Makefile                    convenience targets (wrap the CLI)
  config/
    home/                     not a stow pkg; reserved for $HOME-targeted files
    zsh/                      $ZDOTDIR: .zshenv, .zprofile, .zshrc — in-repo zsh config
    stow/                     GNU-stow packages -> symlinked into $HOME
      home/.zshenv            the ONLY zsh file in $HOME (ZDOTDIR bootstrap)
      bash/ git/ atuin/ sheldon/ starship/ task/ bat/ lazygit/
      zellij/                 config.kdl + layouts/ + plugins/ (symlinks → var/vendor)
    shell/                    the framework engine (sourced, never stowed)
      loader.sh               _load_dir/_load_file/_eval_cached/_defer
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
  docs/  man/                 documentation + generated man page
  var/                        GENERATED, gitignored: tools/ vendor/ cache/
```

## ZDOTDIR

`~/.zshenv` (stow package `home`) is the only zsh file in `$HOME`. At startup it:

1. resolves its own real path (through the stow symlink) to locate `$DOTFILES_DIR`;
2. exports `ZDOTDIR="$DOTFILES_DIR/config/zsh"`;
3. sources `$ZDOTDIR/.zshenv`.

zsh then reads the rest of its startup files (`.zprofile`, `.zshrc`, `.zlogin`)
from `$ZDOTDIR` automatically. Result: `$HOME` stays clean and there are no
per-file zsh symlinks.

## Startup / load order

`.zshenv` (every zsh): `loader.sh` → `core/00-env.sh` → active profile `secrets.sh`.

`.zprofile` (login only): `dotfiles stow --if-needed` → profile `login.sh` →
`~/.zprofile.$USER`.

`.zshrc` (interactive): `core/10-functions.sh` → `core/20-aliases.sh` →
profile `aliases.sh` → `config/shell/zsh/*` → `conf.d/*` → profile `tools.sh` →
profile `company.sh`.

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
| 50 | ensure-stowed | self-heal symlinks (deferred) |
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

- `var/tools/` — self-installed CLI binaries (on PATH first).
- `var/vendor/` — cloned zsh plugins, zsh-defer, Zellij WASM plugins (`zellij-plugins/`).
- `var/cache/` — installer scratch.

Durable shell state (zcompdump, init caches, history) lives under XDG
(`~/.cache`, `~/.local/state`), **not** in `var/`. To reinstall cleanly:
`rm -rf var && ./install.sh`.
