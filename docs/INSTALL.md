# Install

## Requirements

- `git`, `curl`, a POSIX `sh`, and `zsh` (the interactive shell).
- Network access to GitHub releases (aqua + plugins).
- A C toolchain only for legacy source builds (`zsh`, optional `task`/`timew`).

## What it does

```sh
./install.sh                 # = install/bootstrap.sh
```

Steps (see `install/steps/`):

1. **host-setup** — dirs, PATH stubs, basic host prep.
2. **fetch-themes** — Catppuccin Mocha assets (starship, bat, delta) into `home/`.
3. **install-tools** — [aqua](https://aquaproj.github.io/) installs CLIs from `aqua.yaml`
   into `var/tools/aqua` (rootless, no sudo). Then legacy `install/tools/*.sh` for
   packages not in aqua-registry (`zsh`, `broot`, `betterleaks`, `dotfiles-tools`, …).
   Optional tools: `--with-optional-tools` (aqua tag `optional` + legacy optionals).
4. **install-zellij-plugins** — WASM plugins into `var/vendor/zellij-plugins/`.
5. **install-sheldon-plugins** — clones zsh plugins + `zsh-defer` into `var/vendor`.
6. **install-fonts** — copies bundled fonts from `nerdfonts/` into
   `~/.local/share/fonts` (never re-downloads; skip if already present).
7. **dotfiles apply** + **compile** + **doc man**.

Flags: `--skip-tools`, `--skip-fonts`, `--fetch-theme`, `--with-optional-tools`.

## Tools only

```sh
dotfiles update-tools
dotfiles update-tools --with-optional
# or:
bash install/steps/install-tools.sh --aqua-only
bash install/steps/install-tools.sh --legacy-only
```

## After install

```sh
exec zsh -l
dotfiles reload     # recompile + re-exec
dotfiles doctor
man dotfiles
```

## Fresh / clean reinstall

`var/` is the only generated tree:

```sh
rm -rf var && ./install.sh
```

Fonts under `nerdfonts/` stay in the repo; wipe only if you intend to remove them.

## Where things live

| Kind | Location |
|---|---|
| zsh config | in-repo `config/zsh` (via `ZDOTDIR`) |
| aqua CLIs | `var/tools/aqua` (`AQUA_ROOT_DIR`, on `PATH`) |
| legacy CLIs | `var/tools/bin` |
| plugins | `var/vendor` |
| fonts (source) | `nerdfonts/` (bundled) |
| fonts (installed) | `~/.local/share/fonts` |
| caches/state | `~/.cache`, `~/.local/state` (XDG) |
| secrets/overrides | `$DOTFILES_LOCAL/profile/*.sh` (gitignored; see NAMING.md) |

Create `local/profile/*.sh` as needed — templates under `config/templates/profile/`.

For cluster / work machines (optional), create `local/profile/company.sh` with your cluster module sources.

## Getting the dotfiles on another machine

Clone over git — machine-specific state (`local/`, `var/`) is already gitignored, so a
plain clone + `./install.sh` is all a new host needs:

```sh
git clone <remote> ~/Git/dotfiles-chzemoi && cd ~/Git/dotfiles-chzemoi && ./install.sh
```

## Uninstall

1. `install/cleanup.sh` (backs up state; chezmoi destroy on reset).
2. Remove `~/.zshenv` and restore your previous shell startup files.
3. `rm -rf var` and the repo.
