# starship — cross-shell prompt. Loaded late so it owns the final prompt setup.
# NOT deferred: it draws the prompt, so it must initialize synchronously.
_init_tool_hook starship
