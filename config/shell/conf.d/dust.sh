# dust — modern du (largest entries first).
command -v dust >/dev/null 2>&1 || return 0
alias du='dust -r'
