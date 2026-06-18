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

## Local / untracked overrides (never in the repo)

| Path | Purpose |
|---|---|
| `$DOTFILES_LOCAL/env.local` | secrets/env, loaded in all shells |
| `$DOTFILES_LOCAL/aliases.local` | personal aliases |
| `$DOTFILES_LOCAL/conf.d/` | extra per-tool drop-ins |
| `$DOTFILES_LOCAL/functions/` | extra autoloaded functions |
| `~/.zshrc.$USER` | host/user-specific zsh tweaks |

`$DOTFILES_LOCAL` defaults to `$XDG_CONFIG_HOME/dotfiles.local`.
