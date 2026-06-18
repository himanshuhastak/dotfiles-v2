# config/shell/zsh/02-zmodload.zsh — load zsh builtin modules up front.
# Preferring builtins over external commands avoids forking (e.g. `date`) on a
# hot path and lets later modules use them: $terminfo for robust key bindings,
# complist for the colored completion menu. zmodload is idempotent and cheap.
zmodload zsh/datetime 2>/dev/null   # $EPOCHSECONDS + strftime builtin (no `date` fork)
zmodload zsh/mathfunc 2>/dev/null   # sin()/sqrt()/… usable inside $(( ... ))
zmodload zsh/terminfo 2>/dev/null   # $terminfo[...] for terminal-correct key bindings
zmodload zsh/complist 2>/dev/null   # colored completion menu + interactive menu selection
