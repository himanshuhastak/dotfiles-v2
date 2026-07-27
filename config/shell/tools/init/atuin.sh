# atuin — shell history database. Loads after fzf so atuin owns Ctrl-R.
# --disable-up-arrow leaves the up key for zsh history-substring-search.
_init_tool_hook atuin --defer --disable-up-arrow
