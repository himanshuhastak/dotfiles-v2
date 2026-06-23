# Install

## Requirements

- `git`, `curl`, a POSIX `sh`, and `zsh` (the interactive shell).
- A C toolchain (`cmake`/`make`/compiler) only for the few source-built tools
  (e.g. taskwarrior); everything else is a prebuilt static binary.
- Network access to GitHub releases (for tools + plugins + fonts).

## What it does

```sh
./install.sh                 # = install/bootstrap.sh
```

Steps (see `install/steps/`):

1. **install-stow** — builds the bundled stow (python, no Perl) into `install/bin`.
2. **fetch-themes** — Catppuccin Mocha assets (starship, bat, delta).
3. **install-tools** — installs ~30 CLIs into `var/tools/bin` (GNU parallel first,
   then the rest in parallel; pass `--sequential-tools` to `install.sh` to opt out),
   quality tools `shellcheck`, `shfmt`, `bats`, `zshellcheck` (zsh linter),
   `betterleaks` (secrets), `actionlint`, `editorconfig-checker`. Self-owned;
   never reuses system/NFS binaries.
4. **install-zellij-plugins** — downloads `zsm`, `zjframes`, `monocle`
   into `var/vendor/zellij-plugins/` and symlinks them into the zellij stow package.
5. **stow-dotfiles** — symlinks the `config/stow/*` packages into `$HOME`
   (notably `~/.zshenv`, the ZDOTDIR bootstrap).
6. **install-sheldon-plugins** — clones zsh plugins + `zsh-defer` into `var/vendor`.
7. **install-fonts** — JetBrainsMono Nerd Font.
8. **fix-task-hooks**, then **compile** (`.zwc`) and **doc man**.

Flags: `--skip-tools`, `--skip-fonts`, `--fetch-theme`, `--sequential-tools`.

## After install

```sh
exec zsh
dotfiles doctor      # verify paths, tools, symlinks
man dotfiles         # full CLI reference
dotfiles bench       # measure startup time
```

## Fresh / clean reinstall

`var/` is the only generated tree:

```sh
rm -rf var && ./install.sh
```

## Where things live

| Kind | Location |
|---|---|
| zsh config | in-repo `config/zsh` (via `ZDOTDIR`) |
| tools | `var/tools/bin` (on `PATH`) |
| plugins | `var/vendor` |
| caches/state | `~/.cache`, `~/.local/state` (XDG) — **not** in `var/` |
| secrets/overrides | `$DOTFILES_LOCAL/profile/*.sh` (gitignored; see NAMING.md) |

Create `local/profile/*.sh` as needed — nothing is shipped as templates.

For cluster / work machines (optional):

```sh
printf '/scratch/$USER:scratch\n/tmp:tmp\n' > local/profile/mount.lst
# create local/profile/company.sh with your cluster module sources
dotfiles work-stow
```

`mount.lst` format: `path:shortname` (one per line, `#` comments ok).

## ~/Work disk links

```sh
dotfiles work-stow    # reads local/profile/mount.lst -> ~/Work/scratch, ~/Work/tmp, …
```

Stow builds a temporary package under `var/work/` (generated, gitignored) and
links it into `~/Work/`. It is **not** in `config/stow/` because mount paths are
machine-specific and derived from your `mount.lst`.

Edit `local/profile/mount.lst`, then re-run `dotfiles work-stow`.

## Sync from another machine

Use a **trailing slash** on the source path so hidden files (`.gitignore`, `.editorconfig`, …) copy correctly. Never use `SOURCE/*` — the shell glob skips dotfiles.

```sh
dotfiles sync arctest5:~/dotfiles-v2/
# or set once:  export DOTFILES_SYNC_SOURCE=arctest5:~/dotfiles-v2/
dotfiles sync
```

Equivalent manual command:

```sh
rsync -avzl -e ssh \
  --exclude 'var/' \
  --exclude '*.zwc' \
  --exclude '.git/' \
  --exclude 'local/profile/*.sh' \
  --exclude 'local/profile/mount.lst' \
  --exclude 'local/disabled' \
  --exclude 'local/mount.lst' \
  arctest5:~/dotfiles-v2/ \
  ~/dotfiles-v2/
```

`local/profile/*` and `local/disabled` are excluded so machine-specific config stays on each host. Only `local/profile/.gitignore` is tracked in git.

## Uninstall

1. `install/cleanup.sh` (unstows symlinks, backs up state).
2. Remove `~/.zshenv` and restore your previous shell startup files.
3. `rm -rf var` and the repo.
