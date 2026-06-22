# Naming & conventions

## Module files (framework)

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
- For profile files, `<name>` is the basename without `.sh` (e.g. `company`).

## Local profile (`$DOTFILES_DIR/local/profile/`)

`$DOTFILES_LOCAL` defaults to `$DOTFILES_DIR/local`. Per-user config lives in
`$DOTFILES_LOCAL/profile/*.sh`. Only `profile.example/` templates are tracked in
git — copy them to `profile/` and drop the `.example` suffix.

**Stable semantic files** (fixed names; load timing is hardcoded in the entrypoints):

| File | Loaded from | Use for |
|---|---|---|
| `secrets.sh` | `.zshenv` / `00-env.sh` | every shell — secrets, PATH, exports |
| `login.sh` | `.zprofile` | login zsh only |
| `aliases.sh` | `.zshrc` (early) | interactive aliases |
| `tools.sh` | `.zshrc` (after compinit) | per-tool hooks |
| `company.sh` | `.zshrc` (last) | work / cluster env |

`local/disabled` — module toggles (`dotfiles disable`); not a profile file.

Quick start:

```sh
mkdir -p local/profile
cp local/profile.example/*.example local/profile/
for f in local/profile/*.example; do mv "$f" "${f%.example}"; done
exec zsh
```

Skip one file on a machine: `dotfiles disable company`.

## Host-specific tweaks (outside the repo)

| Path | Purpose |
|---|---|
| `~/.zshrc.$USER` | host/user-specific zsh tweaks |
| `~/.zprofile.$USER` | host/user-specific login tweaks |

Override the local root with `export DOTFILES_LOCAL=/path/to/other` if needed.
