# Chezmoi integration

This branch replaces **GNU stow** with [chezmoi](https://www.chezmoi.io/). The `dotfiles` CLI wraps chezmoi — you do not need to run `chezmoi` directly.

## Apply flow

```text
dotfiles apply
    → chezmoi --config home/.chezmoi.toml --source home/ apply
    → symlink mode: static files → symlinks into home/
    → templates (*.tmpl) → rendered copies in $HOME
    → stages local/profile/ssh.local → home/dot_ssh/config.d/local.conf
```

Login shells run `dotfiles apply --if-needed` from `.zprofile`.

## Source tree

| Path | Purpose |
|------|---------|
| `home/` | Files deployed to `$HOME` (`.zshenv`, `.ssh`, `.config`, …) |
| `home/*.tmpl` | Templates (`{{ .chezmoi.sourceDir }}` for repo path) |
| `data/*.toml` | Default chezmoi data (merged with `local/data/*.toml` on apply) |
| `local/profile/` | Shell profiles + `ssh.local` (staged on apply) |
| `home/.chezmoi.toml` | Chezmoi config (`mode = "symlink"`, data, templates) |

## Symlink mode

`home/.chezmoi.toml` sets `mode = "symlink"`. After `dotfiles apply`, most static dotfiles in `$HOME` are **symlinks** back to `home/` in the repo (like GNU stow). Edit `home/dot_gitconfig` (or `~/.gitconfig` — same file) and changes are live without re-apply.

**Not symlinked** (chezmoi renders or copies instead):

- Templates (`dot_zshenv.tmpl`, `dot_bashrc.tmpl`) — run `dotfiles apply` after edits
- Encrypted, private, or executable targets
- Whole directories (contents are symlinked file-by-file where allowed)
- Pre-existing `symlink_*` entries (e.g. zellij WASM plugins → `var/vendor/`)

The CLI passes `--config home/.chezmoi.toml` so symlink mode is always active.

## Machine-specific SSH

**Option A** — edit `local/profile/ssh.local`, then `dotfiles apply`.

**Option B** — `dotfiles ssh add myhost -H 10.0.0.1 -F 5902:5902` (writes ssh.local + apply).

**Option C** — data file `local/data/ssh.toml` (see `local/data/ssh.toml.example`).

## Removed (vs workflow branch)

- `config/stow/` entire tree
- `install/steps/install-stow.sh`, `stow-dotfiles.sh`
- `install/bin/stow.py` (~2000 lines)
- `bin/lib/*.sh` (logic consolidated into `bin/dotfiles`)
- Separate `fix-ssh-config.sh` (chezmoi manages SSH layout)

## Install

`./install.sh` installs tools (including chezmoi), plugins, fonts, then runs `dotfiles apply`.

## Cleanup

`install/cleanup.sh` backs up `$HOME` files from `home/` mapping and can `chezmoi destroy` on reset.
