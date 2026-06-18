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

## Local overrides (`$DOTFILES_DIR/local/`)

`$DOTFILES_LOCAL` defaults to `$DOTFILES_DIR/local`. Only `*.example` templates are
tracked; copy a template to `NN-name.sh` (e.g. `00-09-secrets.example` →
`00-secrets.sh`) — your copies are gitignored.

**Pattern:** `NN-name.sh` — e.g. `00-secrets.sh`, `40-company.sh`, `41-client.sh`.
The number sets when the file loads; the name is yours (and the id for
`dotfiles disable <name>`).

| Range | Template | Real file example |
|---|---|---|
| `00–09` | `00-09-secrets.example` | `00-secrets.sh` |
| `10–19` | `10-19-login.example` | `10-login.sh` |
| `20–29` | `20-29-aliases.example` | `20-personal.sh` |
| `30–39` | `30-39-tools.example` | `30-mytool.sh` |
| `40–99` | `40-99-company.example` | `40-company.sh` |

| Range | When loaded | Use for |
|---|---|---|
| `00–09` | every shell | secrets, PATH, exports (scripts too) |
| `10–19` | login zsh | login-only setup |
| `20–29` | interactive | aliases |
| `30–39` | interactive (after compinit) | per-tool hooks |
| `40–99` | interactive (last) | company / personal profile |

`local/disabled` — module toggles (`dotfiles disable`); not numbered.

Quick start:

```sh
cp local/00-09-secrets.example local/00-secrets.sh
cp local/40-99-company.example local/40-company.sh
exec zsh
```

Multiple employers: add `40-company.sh`, `41-client.sh` — all in `40–99` load in order.
Skip one on a machine with `dotfiles disable company`.

## Host-specific tweaks (outside the repo)

| Path | Purpose |
|---|---|
| `~/.zshrc.$USER` | host/user-specific zsh tweaks |
| `~/.zprofile.$USER` | host/user-specific login tweaks |

Override the local root with `export DOTFILES_LOCAL=/path/to/other` if needed.
