# Quality & CI

The framework is linted, secret-scanned, tested, and benchmarked. All tools are
installed into `var/tools` by `./install.sh` and invoked through the CLI, a
`Makefile`, a `pre-commit` config, and GitHub Actions.

## Linting — `dotfiles check`

| Tool | Targets |
|---|---|
| `shellcheck` | `.sh` scripts + `bin/dotfiles` + `config/shell/shrc` |
| `zsh -n` | every zsh file (parse check; the always-available floor) |
| [`zshellcheck`](https://github.com/afadesigns/zshellcheck) | zsh static analysis (setopts/hooks/globs shellcheck can't see) |
| [`actionlint`](https://github.com/rhysd/actionlint) | `.github/workflows/*.yml` |
| [`editorconfig-checker`](https://github.com/editorconfig-checker/editorconfig-checker) | all files vs `.editorconfig` (excludes in `.ecrc`) |

Each tool is optional at runtime: if it isn't installed, `check` skips it and
notes so. Exit status is non-zero if any linter reports a problem.

## Secrets — `dotfiles audit`

[`betterleaks`](https://github.com/betterleaks/betterleaks) (the maintained
successor to gitleaks) scans the working tree. `betterleaks.toml` adds a CEL
prefilter so `var/`, `man/`, `.git/`, `.zwc`, and binary assets are skipped.

## Tests — `dotfiles test`

`bats` smoke tests in `test/` validate framework invariants (loader functions,
env, the ZDOTDIR bootstrap, the `localoptions` regression, the CLI). They avoid
the network and installed tools, so they pass before and after install.

## Benchmark — `dotfiles bench [N]`

Times N interactive `zsh -i -c exit` startups and reports the average.

## pre-commit

`.pre-commit-config.yaml` runs `shellcheck`, `zshellcheck`, `betterleaks`, and
`actionlint` on staged files:

```sh
pip install pre-commit && pre-commit install
```

## CI

`.github/workflows/ci.yml` runs `pre-commit` on all files and the `bats` suite on
every push/PR.
