# Productivity tools

One config (non-identity), one keyring (identity + tokens), one CLI.

```text
dotfiles secrets   → URLs, emails, usernames, tokens (OS keyring)
local/tools/config.toml → verify_ssl, root_group_id, JQL, access_level
```

## Setup (once)

```sh
# Put a modern python3 on PATH yourself (or set DOTFILES_PYTHON=/path/to/python3).
# The installer never picks an interpreter or loads modules for you.
dotfiles update-tools dotfiles-tools
# → var/tools/python/<X.Y>/dotfiles-tools
# → var/tools/python/current → <X.Y>

mkdir -p "$DOTFILES_DIR/local/tools"
cp "$DOTFILES_DIR/tools/config.toml.example" "$DOTFILES_DIR/local/tools/config.toml"
# edit: root_group_id, default_project, verify_ssl, bugwarrior query — only

# Identity + credentials (keyring — not config.toml)
dotfiles secrets set jira_url
dotfiles secrets set jira_email
dotfiles secrets set jira_api_token
dotfiles secrets set gitlab_url
dotfiles secrets set gitlab_token
dotfiles secrets set gitlab_email_domain   # optional, for bare usernames

dotfiles bugwarrior render
dotfiles jira test
```

## What goes in keyring vs config

| Keyring (`dotfiles secrets`) | `config.toml` (local only) |
|------------------------------|----------------------------|
| `jira_url` | `jira.verify_ssl` |
| `jira_email` / `jira_username` | `jira.default_project` |
| `jira_api_token` / `jira_password` | `jira.api_version` |
| `gitlab_url` | `gitlab.root_group_id` |
| `gitlab_token` | `gitlab.access_level` |
| `gitlab_email_domain` | `gitlab.verify_ssl` |
| | `[bugwarrior.*]` queries |

**Do not put URLs, emails, or usernames in config.toml.**

## Commands

```sh
dotfiles secrets list
dotfiles secrets set jira_url --value 'https://jira.example.com'

dotfiles jira test
dotfiles gitlab list
dotfiles bugwarrior pull
```

## Credentials backend

Uses OS keyring when available (macOS Keychain, Secret Service). On headless
SSH/cluster hosts it falls back to `local/tools/keyring.json` (mode `0600`,
gitignored under `local/`).

```sh
dotfiles secrets list   # shows Backend: os-keyring (…) or file (…)
```

