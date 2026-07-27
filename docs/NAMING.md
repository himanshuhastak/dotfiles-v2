# Naming

## Shell modules

- **Filename = module name** for `dotfiles disable <name>` (no numeric prefixes).
- **`.sh`** — portable (bash + zsh): `env.sh`, `tools/*.sh`
- **`.zsh`** — zsh-only: `config/shell/zsh/*.zsh`

## Load order

| Layer | Controlled by |
|-------|-------------|
| `zsh/*.zsh` | explicit list in `config/zsh/.zshrc` |
| `tools/init/*` | `tools/init.sh` |
| `tools/*.sh` | alphabetical (after init) |
| `local/profile/*.sh` | semantic names + fixed hooks in entrypoints |

## Local profile (`local/profile/`)

| File | Loaded from | Use |
|------|-------------|-----|
| `local.sh` | `.zshenv` / `env.sh` | PATH, machine env |
| `aliases.sh` | `.zshrc` | personal aliases |
| `tools.sh` | `.zshrc` | tool overrides |
| `company.sh` | `.zshrc` (last) | cluster / LSF |
| `login.sh` | `.zprofile` | login-only |
| `ssh.local` | chezmoi apply | SSH hosts |

## Toggles

`dotfiles disable <name>` writes to `local/disabled`. Module name = file basename without extension.
