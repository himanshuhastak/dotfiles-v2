# Install

## Requirements

- `git`, `curl`, a POSIX `sh`, and `zsh` (the interactive shell).
- A C toolchain (`cmake`/`make`/compiler) only for the few source-built tools
  (e.g. taskwarrior); everything else is a prebuilt static binary.
- Network access to GitHub releases (for tools + plugins).

## What it does

```sh
./install.sh                 # = install/bootstrap.sh
```

Steps (see `install/steps/`):

1. **install-stow** — builds the bundled stow (python, no Perl) into `install/bin`.
2. **fetch-themes** — Catppuccin Mocha assets (starship, bat, delta).
3. **install-tools** — installs core CLIs into `var/tools/bin` in parallel. **Required:**
   `zsh` (built from source), `sheldon` (zsh plugin manager), and other non-optional
   entries in `config/tools.toml`. **Skipped by default** (use `--with-optional-tools`):
   latest `bash`, `ble.sh`, `rust`, `task`, `timew`, `bugwarrior`, and other
   `optional = true` entries in `config/tools.toml`.
4. **install-zellij-plugins** — downloads `zsm`, `zjframes`, `monocle`
   into `var/vendor/zellij-plugins/` and symlinks them into the zellij stow package.
5. **stow-dotfiles** — symlinks the `config/stow/*` packages into `$HOME`
   (notably `~/.zshenv`, the ZDOTDIR bootstrap).
6. **install-sheldon-plugins** — clones zsh plugins + `zsh-defer` into `var/vendor`.
7. **install-fonts** — all bundled Nerd Fonts from `nerdfonts/` (FiraMono, JetBrains Mono, …). Remove JetBrains manually via `install/steps/remove-jetbrains-font.sh` if needed.
8. **fix-ssh** — `~/.ssh` permissions + ensure local `.pub` keys are in `authorized_keys`.
9. **fix-ssh-config** — SSH `Include` snippets (`config.d/`) + optional `local/profile/ssh.local`.
10. **fix-x11-forwarding** — XAUTH patch when `DISPLAY` is set (also on each zsh login).
11. **fix-task-hooks**, then **compile** (`.zwc`) and **doc man**.

**Conditional stow:** packages `ssh` and `vnc` are skipped when `~/.ssh` or `~/.vnc`
already contains keys, `vncpasswd`, or hand-edited config. Use `local/profile/ssh.local`
and `fix-ssh-config` to merge generic settings on existing machines.

Flags: `--skip-tools`, `--skip-fonts`, `--fetch-theme`, `--sequential-tools`, `--with-optional-tools`.

## After install

```sh
exec zsh          # re-execs to var/tools/bin/zsh when installed
dotfiles reload     # recompile + re-exec self-built zsh
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

## SSH & VNC

`install.sh` always stows managed `ssh` + `vnc` files (never keys or `vncpasswd`).

Edit tracked placeholders in `local/profile/` — see `local/profile/README.md`.

```sh
dotfiles profile-init    # migrate legacy SSH + ssh-sync
dotfiles ssh-migrate     # once: ~/.ssh/config → ssh.local
dotfiles ssh-sync
vncpasswd && vncstart
```

TigerVNC Viewer: resize window or fullscreen for client-driven resolution.

See `tools/examples/vnc.md`.

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

`dotfiles sync` excludes `local/profile/secrets.sh` and `local/disabled`.
Profile placeholders ship in git — edit for each machine.

## Uninstall

1. `install/cleanup.sh` (unstows symlinks, backs up state).
2. Remove `~/.zshenv` and restore your previous shell startup files.
3. `rm -rf var` and the repo.
