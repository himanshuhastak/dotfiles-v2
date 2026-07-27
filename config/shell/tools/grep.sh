# config/shell/conf.d/grep.sh — colored grep output.
# The `grep --color=auto` alias lives in core/20-aliases.sh; this adds the
# palette (oh-my-zsh lib/grep.zsh convention). Order-independent drop-in.
export GREP_COLORS="${GREP_COLORS:-mt=01;32}"
