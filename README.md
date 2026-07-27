# dotfiles-chzemoi — chezmoi-backed zsh dotfiles.

Chezmoi deploys `home/` → `$HOME`. Shell framework lives in `config/` (sourced, not copied).
CLIs install via [aqua](https://aquaproj.github.io/) (`aqua.yaml`, rootless — no sudo).

## Quickstart

```sh
cd ~/Git/dotfiles-chzemoi
./install.sh
exec zsh -l
dotfiles profile init
```

## Commands

| Task | Command |
|------|---------|
| Apply to `$HOME` | `dotfiles apply` |
| Update CLIs | `dotfiles update-tools` (aqua + legacy) |
| SSH hosts | `dotfiles ssh add\|edit` |
| VNC | `dotfiles vnc start` |

`dotfiles stow` = `dotfiles apply`.

Static dotfiles use **chezmoi symlink mode** (`home/.chezmoi.toml`): `~/.gitconfig` and similar files symlink into `home/` so edits are live. Templates (`~/.zshenv`) still need `dotfiles apply` after changes.

## Layout

```
aqua.yaml             CLI pins (aqua — primary installer)
home/                 chezmoi source (dot_* → ~/.*)
config/shell/         framework: env.sh, loader.sh, zsh/, tools/
config/zsh/           ZDOTDIR entrypoints (.zshenv, .zshrc, .zprofile)
local/profile/        machine-specific shell + ssh.local
install/              bootstrap; legacy scripts for non-aqua tools
nerdfonts/            bundled fonts (installed locally, not re-fetched)
var/tools/aqua/       aqua root (gitignored)
bin/dotfiles          CLI
```

See [docs/STRUCTURE.md](docs/STRUCTURE.md) and [docs/INSTALL.md](docs/INSTALL.md).
