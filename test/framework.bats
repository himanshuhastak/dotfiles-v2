#!/usr/bin/env bats
# Smoke tests for the dotfiles framework. These avoid the network and installed
# tools so they pass before AND after `./install.sh`.

setup() {
  DF="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export DOTFILES_DIR="$DF"
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export DOTFILES_LOCAL="$HOME/.config/dotfiles.local"
}

@test "loader defines _load_profile and _dotfiles_active_profile" {
  run bash -c '. "$DOTFILES_DIR/config/shell/loader.sh"
    type _load_profile _dotfiles_active_profile >/dev/null'
  [ "$status" -eq 0 ]
}

@test "_defer falls back to synchronous eval in bash" {
  run bash -c '. "$DOTFILES_DIR/config/shell/loader.sh"; _defer "echo deferred-ran"'
  [ "$status" -eq 0 ]
  [ "$output" = "deferred-ran" ]
}

@test "00-env sets DOTFILES_DIR/TOOLS_DIR/SHELDON_DATA_DIR under var/" {
  run bash -c '. "$DOTFILES_DIR/config/shell/loader.sh"
    . "$DOTFILES_DIR/config/shell/core/00-env.sh"
    echo "$TOOLS_DIR"; echo "$SHELDON_DATA_DIR"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"/var/tools"* ]]
  [[ "$output" == *"/var/vendor"* ]]
}

@test "non-interactive zsh sources env silently (no output)" {
  command -v zsh >/dev/null || skip "zsh not installed"
  run zsh -c '. "$DOTFILES_DIR/config/zsh/.zshenv"; print -n ""'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "zsh module setopts persist after _load_dir (localoptions regression)" {
  command -v zsh >/dev/null || skip "zsh not installed"
  run zsh -c '
    . "$DOTFILES_DIR/config/shell/loader.sh"
    d=$(mktemp -d); print "setopt AUTO_PUSHD" > "$d/00-x.zsh"
    _load_dir "$d" zsh
    [[ -o AUTO_PUSHD ]] && print OK || print FAIL'
  [ "$status" -eq 0 ]
  [ "$output" = "OK" ]
}

@test "ZDOTDIR bootstrap derives DOTFILES_DIR and sets ZDOTDIR" {
  command -v zsh >/dev/null || skip "zsh not installed"
  ln -s "$DOTFILES_DIR/config/stow/home/.zshenv" "$HOME/.zshenv"
  run env -i HOME="$HOME" zsh -c 'source $HOME/.zshenv; print "$DOTFILES_DIR"; print "$ZDOTDIR"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"$DOTFILES_DIR"* ]]
  [[ "$output" == *"/config/zsh"* ]]
}

@test "login zsh sources profile login.sh from ZDOTDIR" {
  command -v zsh >/dev/null || skip "zsh not installed"
  ln -s "$DOTFILES_DIR/config/stow/home/.zshenv" "$HOME/.zshenv"
  mkdir -p "$DOTFILES_DIR/local/testprof"
  printf '%s\n' 'print zprofile-local-ran' > "$DOTFILES_DIR/local/testprof/login.sh"
  printf '%s\n' 'testprof' > "$DOTFILES_DIR/local/active"
  run env -i HOME="$HOME" USER=test LOGNAME=test TERM=xterm-256color zsh -l -c 'print done'
  [ "$status" -eq 0 ]
  [[ "$output" == *"zprofile-local-ran"* ]]
  [[ "$output" == *"done"* ]]
}

@test "dotfiles help lists key commands" {
  run "$DOTFILES_DIR/bin/dotfiles" help
  [ "$status" -eq 0 ]
  [[ "$output" == *compile* ]]
  [[ "$output" == *stow* ]]
  [[ "$output" == *bench* ]]
}

@test "dotfiles doc man generates man/dotfiles.1" {
  run "$DOTFILES_DIR/bin/dotfiles" doc man
  [ "$status" -eq 0 ]
  [ -s "$DOTFILES_DIR/man/dotfiles.1" ]
  grep -q '.TH DOTFILES 1' "$DOTFILES_DIR/man/dotfiles.1"
}
