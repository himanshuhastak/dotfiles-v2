# Structure

```
dotfiles-chzemoi/
  aqua.yaml                 aqua CLI pins (primary tool installer)
  home/                     chezmoi → $HOME (dot_zshenv.tmpl → ~/.zshenv, …)
  config/
    zsh/                    ZDOTDIR: .zshenv → env; .zshrc → modules + tools; .zprofile → login
    shell/
      loader.sh             _load_file, _load_profile, _defer, _init_tool_hook
      env.sh                PATH, XDG, AQUA_*, DOTFILES_* (every shell)
      functions.sh          portable functions
      aliases.sh            base aliases
      zsh/                  zsh-only modules (explicit order in .zshrc)
      tools/                per-tool env/aliases
      tools/init/           ordered init hooks (fzf, atuin, zoxide, …)
      lib/                  helpers (doctor, x11)
    templates/profile/      seeds for local/profile/*
  local/profile/            gitignored machine config (ssh.local, company.sh, …)
  install/                  bootstrap + aqua ensure + legacy tool scripts
  nerdfonts/                bundled Nerd Fonts (copied locally; not re-fetched)
  var/tools/aqua/           aqua root (gitignored)
  var/tools/bin/            legacy / source-built binaries
  var/vendor/               sheldon plugins, zellij wasm
  bin/dotfiles              CLI (wraps chezmoi apply)
```

## Startup order (zsh interactive)

1. `$HOME/.zshenv` (chezmoi) → `config/zsh/.zshenv` → `loader.sh` + `env.sh` + `local.sh`
2. Login: `config/zsh/.zprofile` → `dotfiles apply --if-needed`
3. Interactive: `config/zsh/.zshrc` → functions, aliases, zsh modules, `tools/init.sh`, `tools/*.sh`, profiles

No `NN-` filename prefixes — order is explicit in `.zshrc` and `tools/init.sh`.

## Tools

- **aqua** (`aqua.yaml`) installs most GitHub-release CLIs into `var/tools/aqua`.
- **Legacy** `install/tools/*.sh` covers zsh (source), broot, rust, python venv tools, etc.
- Shell aliases/env stay in `config/shell/tools/*.sh` (not generated from aqua).

## Chezmoi

- Source: `home/` (`chezmoi --config home/.chezmoi.toml --source home/`)
- **Symlink mode** (`mode = "symlink"` in `home/.chezmoi.toml`): static `$HOME` files symlink back to `home/`
- Templates: `dot_zshenv.tmpl`, `dot_bashrc.tmpl` (rendered copies — re-apply after edit)
- Machine SSH: staged from `local/profile/ssh.local` on apply (`home/dot_ssh/config.d/local.conf` is gitignored)
