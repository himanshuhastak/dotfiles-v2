# $ZDOTDIR/.zshrc — interactive zsh. (Env is already set by $ZDOTDIR/.zshenv.)

# Startup profiler — `DOTFILES_PROFILE=1 zsh -i` (or `dotfiles profile`) dumps a
# zprof timing report at the end so slow init can be spotted. Must load first.
[[ -n "${DOTFILES_PROFILE:-}" ]] && zmodload zsh/zprof

# Portable shared base: functions + base aliases (env already done in .zshenv).
source_r "$DOTFILES_DIR/config/shell/core/10-functions.sh"
source_r "$DOTFILES_DIR/config/shell/core/20-aliases.sh"
_load_local 20 29

# Only interactive shells run the rest.
[[ -o interactive ]] || return

# zsh interactive modules, in order:
#   00-options 05-directories 10-history 15-zmodload 20-completion(compinit)
#   30-termsupport 40-hashdirs 90-defer 95-plugins 99-keybindings
# 90-defer sources zsh-defer and upgrades _defer() to run things asynchronously
# (after the first prompt). 95-plugins (sheldon) + the conf.d tool hooks below
# therefore start instantly and finish loading in the background.
_load_dir "$DOTFILES_DIR/config/shell/zsh" zsh

# Per-tool drop-ins — loaded AFTER compinit so completion/key hooks register
# correctly. Repo defaults first, then local overrides.
_load_dir "$DOTFILES_DIR/config/shell/conf.d"
_load_local 30 39

# Company / personal profile (interactive only; not loaded in scripts).
_load_local 40 99

# Host/user-specific zsh-only tweaks (untracked, in $HOME — never the repo).
[[ -r ~/.zshrc.$USER ]] && . ~/.zshrc.$USER

# Profiler report (only when DOTFILES_PROFILE was set above).
[[ -n "${DOTFILES_PROFILE:-}" ]] && zprof
