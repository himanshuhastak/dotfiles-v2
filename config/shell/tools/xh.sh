# xh — friendly HTTP client (httpie-compatible, written in Rust).
# xh is a drop-in replacement for httpie/http with much faster startup.
command -v xh >/dev/null 2>&1 || return 0

alias http='xh'
alias https='xh --https'
