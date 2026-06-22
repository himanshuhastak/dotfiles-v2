# dotfiles

A fast, modular, stow-based shell environment for zsh (with a bash script
fallback). Self-locating, self-healing, byte-compiled, and asynchronously
loaded for an instant prompt.

## Highlights

- **ZDOTDIR layout** — the only zsh file in `$HOME` is `~/.zshenv`; everything
  else lives in-repo under `config/zsh` (no per-file symlinks).
- **Self-locating** — entrypoints derive `$DOTFILES_DIR` from their own symlink,
  so the repo can live anywhere.
- **Async startup** — heavy tool hooks load after the first prompt via
  [zsh-defer](https://github.com/romkatv/zsh-defer); `starship` stays synchronous.
- **Modular** — numbered drop-ins under `config/shell/{core,zsh,conf.d}` and semantic
  `local/profile/*.sh`, each toggleable with `dotfiles disable <name>`.
- **Self-owned tools** — ~30 CLIs installed into `var/tools` (never reuses
  system/NFS binaries); zsh plugins vendored into `var/vendor`.
- **`var/` is the only generated tree** — wipe it for a clean reinstall.
- **Quality-gated** — `shellcheck` + `zshellcheck` (zsh), `shfmt`, `bats`,
  `betterleaks` (secrets), `actionlint`, `editorconfig-checker`, `pre-commit`, CI.

## Quickstart

```sh
git clone <repo> ~/dotfiles_v2
cd ~/dotfiles_v2
./install.sh            # tools + plugins + stow + fonts + compile
exec zsh
```

## The `dotfiles` CLI

| Command | Purpose |
|---|---|
| `dotfiles list` | list modules and on/off state |
| `dotfiles enable\|disable <name>` | toggle a module (persists) |
| `dotfiles reload` | recompile + re-exec the shell |
| `dotfiles compile` | byte-compile the framework (`.zwc`) |
| `dotfiles stow [--if-needed]` | (re)create symlinks |
| `dotfiles doctor` | health checks |
| `dotfiles check` | lint scripts (shellcheck `.sh` + zsh -n/zshellcheck `.zsh` + actionlint + editorconfig) |
| `dotfiles audit` | scan the working tree for secrets (betterleaks) |
| `dotfiles test` | run the bats smoke tests |
| `dotfiles bench [N]` | benchmark startup time |
| `dotfiles profile` | zprof timing report |
| `dotfiles doc man` | regenerate `man dotfiles` |

Run `man dotfiles` after install for the full reference.

## Documentation

- [docs/STRUCTURE.md](docs/STRUCTURE.md) — layout, load order, ZDOTDIR, `var/`.
- [docs/INSTALL.md](docs/INSTALL.md) — installing, requirements, uninstalling.
- [docs/NAMING.md](docs/NAMING.md) — module naming + load-order conventions.
- [docs/FUNCTIONS.md](docs/FUNCTIONS.md) — portable functions + autoloaded `functions/`.
- [docs/QUALITY.md](docs/QUALITY.md) — linting, secret-scanning, tests, CI, pre-commit.

## License

This repository is [MIT licensed](LICENSE). Copyright (c) 2026 Himanshu Hastak.

It is personal shell configuration, shared publicly so friends can fork and
adapt it. Paths, usernames, and machine-specific settings are examples — replace
them with your own. Do not commit secrets; copy `local/profile.example/` templates to
`local/profile/*.sh` (your copies are gitignored).

**Third-party code** is not covered by this MIT license and remains under its
original terms:

- **Vendored plugins and libraries** installed into `var/vendor/` (zsh plugins,
  zsh-defer, Zellij WASM plugins, etc.) keep their upstream licenses unchanged.
- **Self-installed tools** under `var/tools/` are upstream binaries or builds;
  each project’s license applies to that software.
- **Fetched theme assets** (Starship, bat, delta, etc.) retain the licenses of
  their respective projects.
- **Adapted snippets** in this repo (e.g. clipboard helpers, keybinding patterns)
  may include attribution in source comments; those portions remain governed by
  their original licenses where applicable.

Only the original framework, config, and installer code in this repository
(outside `var/`) is offered under MIT unless a file states otherwise.

