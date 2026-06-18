# Functions

There are two places for functions, by portability.

## Portable functions — `config/shell/core/10-functions.sh`

Loaded in **both** bash and zsh. Keep them POSIX-ish. Current set:

| Function | Purpose |
|---|---|
| `date_ist [args]` | `date` in Asia/Calcutta |
| `bkup <path>` | move `<path>` to `<path>.bkp` (archives an existing backup) |
| `bkp <path>` | copy `<path>` to `<path>.bkp` |
| `untar_file <file>` | extract any common archive type |
| `mkcd <dir>` | `mkdir -p` then `cd` |
| `cd <dir>` | smart cd: normal paths, then zoxide `z` fallback |
| `Calc <expr>` | python eval with decimal/hex/binary output |

## Autoloaded zsh functions — `config/shell/functions/`

zsh-only. **One function per file; the filename is the function name.** They are
autoloaded (parsed lazily on first call), so adding more costs nothing at startup.
`45-functions.zsh` puts `config/shell/functions` on `fpath` and `autoload -Uz`
each file. Define extra functions in `local/20-*.sh` or `local/40-*.sh` instead.

Shipped examples:

| Function | Purpose |
|---|---|
| `up [N]` | cd up N parent directories (default 1) |
| `fcd` | fuzzy-cd into a subdirectory (fzf + fd/find) |
| `clipcopy [file]` | copy a file (or stdin) to the system clipboard |
| `clippaste` | write the system clipboard to stdout |

`clipcopy`/`clippaste` are cross-platform: on first use `detect-clipboard`
auto-selects a backend for the current environment (macOS `pbcopy`, Wayland
`wl-copy`, X11 `xsel`/`xclip`, Windows `clip.exe`/`win32yank`, SSH `lemonade`,
tmux `load-buffer`, Termux, …) and redefines both functions to wrap it. Examples:
`pwd | clipcopy`, `clipcopy ~/.ssh/id_ed25519.pub`, `clippaste > out.txt`.

### Adding one

```zsh
# config/shell/functions/hello
#autoload
emulate -L zsh          # isolate options/aliases to this function
print "hi, $1"
```

Then `hello world` works in a new shell (or `autoload -Uz hello` now). Use
`emulate -L zsh` at the top so the function is robust regardless of global options,
and avoid the reserved name `path` for locals (it is tied to `$PATH`).
