# config/shell/zsh/05-directories.zsh — directory stack navigation.
# Adapted from oh-my-zsh lib/directories.zsh. Loads early (before completion)
# so `d` and the numbered jumps get the dirstack completion menu.

setopt AUTO_PUSHD        # cd pushes the old dir onto the stack
setopt PUSHD_IGNORE_DUPS # no duplicate entries
setopt PUSHD_SILENT      # don't print the stack after pushd/popd
setopt PUSHD_TO_HOME     # pushd with no args goes $HOME (like cd)

# `d` lists the stack; 1..9 jump to that entry.
alias d='dirs -v | head -10'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
