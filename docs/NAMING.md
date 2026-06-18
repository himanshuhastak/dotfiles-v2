# Naming & conventions

## Module files

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
| 50–89 | maintenance / conditional hooks |
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

## Local profiles (`$DOTFILES_DIR/local/`)

`$DOTFILES_LOCAL` defaults to `$DOTFILES_DIR/local`. The tracked template is
`local/example/`; real profile dirs (`local/gfs/`, etc.) and `local/active` are
gitignored.

### Layout

```
local/
  active                 one line: profile name (managed by `dotfiles use`)
  disabled               module toggles (`dotfiles disable`)
  example/               tracked template — copy to `local/<your-profile>/`
    secrets.sh
    login.sh
    aliases.sh
    tools.sh
    company.sh
  gfs/                   real profile (gitignored, not pushed)
```

### Fixed drop-in names (per profile)

| File | When loaded | Use for |
|---|---|---|
| `secrets.sh` | every shell | secrets, PATH, exports (scripts too) |
| `login.sh` | login zsh | login-only setup |
| `aliases.sh` | interactive | aliases |
| `tools.sh` | interactive (after compinit) | per-tool hooks |
| `company.sh` | interactive (last) | work / employer env |

Only create the files you need; missing phases are skipped.

### Activation

```sh
cp -r local/example local/gfs
dotfiles use gfs          # writes local/active
exec zsh
```

Override for one session: `DOTFILES_PROFILE=gfs zsh -l`.

Skip a profile on a machine: `dotfiles disable gfs`.

### Multiple profiles

Keep several dirs (`local/gfs/`, `local/personal/`) and switch with
`dotfiles use <name>`. Only the active profile's drop-ins load.

## Host-specific tweaks (outside the repo)

| Path | Purpose |
|---|---|
| `~/.zshrc.$USER` | host/user-specific zsh tweaks |
| `~/.zprofile.$USER` | host/user-specific login tweaks |

Override the local root with `export DOTFILES_LOCAL=/path/to/other` if needed.
