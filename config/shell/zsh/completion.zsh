# config/shell/zsh/20-completion.zsh — completion system.
# Runs BEFORE plugins (95) so fpath is complete when compinit builds the dump
# and before fzf-tab wraps the completion widgets. The zsh-completions plugin
# only contributes extra completion *functions* via fpath, so its src dir must
# be on fpath here (sheldon sources it later, which is too late for compinit).

# Completion-related shell options (prezto). EXTENDED_GLOB is also needed for the
# (#q...) glob qualifiers used below.
setopt EXTENDED_GLOB    # glob modifiers (#q...) + compinit globbing
setopt COMPLETE_IN_WORD # complete from both ends of the word
setopt ALWAYS_TO_END    # move the cursor to the end after completion
setopt AUTO_MENU        # show the completion menu on a second tab
setopt AUTO_LIST        # list choices on an ambiguous completion
setopt AUTO_PARAM_SLASH # add a trailing slash when completing a directory
setopt PATH_DIRS        # path search even for commands with slashes
unsetopt MENU_COMPLETE  # do not insert the first match automatically
unsetopt FLOW_CONTROL   # free up ^Q / ^S

# Our own extra completion functions (drop _tool files in config/shell/completions/).
_cd="$DOTFILES_DIR/config/shell/completions"
[[ -d "$_cd" ]] && fpath=("$_cd" $fpath)
unset _cd

_zc="${SHELDON_DATA_DIR:-$DOTFILES_DIR/var/vendor}/repos/github.com/zsh-users/zsh-completions/src"
[[ -d "$_zc" ]] && fpath=("$_zc" $fpath)
unset _zc

ZDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
[[ -d "${ZDUMP:h}" ]] || command mkdir -p "${ZDUMP:h}"
[[ -d "${ZDUMP:h}/zcompcache" ]] || command mkdir -p "${ZDUMP:h}/zcompcache"

autoload -Uz compinit
# Regenerate the dump at most once a day (glob qualifier: modified > 24h ago);
# otherwise trust it and skip the security check for a faster start.
if [[ -n "$ZDUMP"(#qN.mh+24) ]]; then
  compinit -d "$ZDUMP"
else
  compinit -C -d "$ZDUMP"
fi

# Compile the dump so subsequent starts load bytecode.
if [[ ! -s "$ZDUMP.zwc" || "$ZDUMP" -nt "$ZDUMP.zwc" ]]; then
  zcompile "$ZDUMP" 2>/dev/null
fi

# --- completion behaviour (grml/prezto-grade) -------------------------------
# Completers: exact, then partial-word match, then typo-tolerant approximate.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Cache slow-to-build completions (apt/dpkg/etc.) under XDG.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Interactive menu + colored candidate list (reuses LS_COLORS from 04-colors).
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Matching: case-insensitive, then partial-word (foo-bar from f-b), then substring.
zstyle ':completion:*' matcher-list '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Group results by type, with descriptive headers/messages.
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{magenta}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'

# Complete . and .., collapse redundant slashes, keep useful prefixes.
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true

# Nicer process completion for kill/killall (live `ps`, highlighted PIDs).
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,cmd -w -w'
zstyle ':completion:*:*:*:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;32'

# Don't offer internal (_-prefixed) functions or hook stubs as completions.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# --- completion polish (prezto) ---------------------------------------------
# Directories: ordering, dir-stack menu, and surface our named dirs (~dot) under ~.
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

# Hide noise: system users, and show an ignored single match when it's the only one.
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache avahi bin daemon dbus ftp games gdm halt lp mail nobody \
  nscd ntp operator postfix rpc rpcuser shutdown sshd sync uucp xfs '_*'
zstyle '*' single-ignored show

# kill / rm / diff niceties.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:*:kill:*' insert-ids single

# man pages grouped by section.
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# ssh/scp/sftp/rsync host completion harvested from known_hosts, /etc/hosts, and
# ~/.ssh/config (prezto). Robust even when known_hosts is hashed.
zstyle ':completion:*:(ssh|scp|sftp|rsync):*' tag-order \
  'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(ssh|scp|sftp|rsync):*:hosts-host' ignored-patterns \
  '*(.|:)*' loopback localhost broadcasthost
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts(|)(N) 2>/dev/null)"}%%(\#*)*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
