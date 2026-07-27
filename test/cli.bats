#!/usr/bin/env bats

setup() {
  DF="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export DOTFILES_DIR="$DF"
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export DOTFILES_LOCAL="$HOME/dotfiles.local"
  mkdir -p "$DOTFILES_LOCAL/profile"
}

@test "dotfiles profile add creates from template" {
  run "$DOTFILES_DIR/bin/dotfiles" profile add local.sh
  [ "$status" -eq 0 ]
  [ -f "$DOTFILES_LOCAL/profile/local.sh" ]
}

@test "stow is alias for apply" {
  run "$DOTFILES_DIR/bin/dotfiles" help
  [ "$status" -eq 0 ]
  [[ "$output" == *stow* ]]
  [[ "$output" == *apply* ]]
}
