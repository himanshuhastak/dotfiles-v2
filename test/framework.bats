#!/usr/bin/env bats

setup() {
  DF="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export DOTFILES_DIR="$DF"
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export DOTFILES_LOCAL="$HOME/.config/dotfiles.local"
}

@test "loader defines _load_dir, _load_file, _load_profile, _defer" {
  run bash -c '. "$DOTFILES_DIR/config/shell/loader.sh"
    type _load_dir _load_file _load_profile _defer >/dev/null'
  [ "$status" -eq 0 ]
}

@test "env.sh sets TOOLS_DIR/SHELDON_DATA_DIR under var/" {
  export DOTFILES_DIR="$DF"
  run bash -c '. "$DOTFILES_DIR/config/shell/loader.sh"
    . "$DOTFILES_DIR/config/shell/env.sh"
    echo "$TOOLS_DIR"; echo "$SHELDON_DATA_DIR"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"/var/tools"* ]]
  [[ "$output" == *"/var/vendor"* ]]
}

@test "ZDOTDIR bootstrap from chezmoi-style .zshenv" {
  command -v zsh >/dev/null || skip "zsh not installed"
  cat >"$HOME/.zshenv" <<EOF
export DOTFILES_DIR="$DOTFILES_DIR"
export ZDOTDIR="$DOTFILES_DIR/config/zsh"
[[ -r \$ZDOTDIR/.zshenv ]] && source \$ZDOTDIR/.zshenv
EOF
  run env -i HOME="$HOME" zsh -c 'source $HOME/.zshenv; print "$DOTFILES_DIR"; print "$ZDOTDIR"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"$DOTFILES_DIR"* ]]
  [[ "$output" == *"/config/zsh"* ]]
}

@test "dotfiles help lists apply" {
  run "$DOTFILES_DIR/bin/dotfiles" help
  [ "$status" -eq 0 ]
  [[ "$output" == *apply* ]]
}

@test "chezmoi apply deploys .zshenv to temp HOME" {
  export HOME="$BATS_TEST_TMPDIR/chezmoi-home"
  rm -rf "$HOME"; mkdir -p "$HOME"
  run env HOME="$HOME" DOTFILES_DIR="$DOTFILES_DIR" "$DOTFILES_DIR/bin/dotfiles" apply
  [ "$status" -eq 0 ]
  [ -f "$HOME/.zshenv" ]
  [[ "$(cat "$HOME/.zshenv")" == *"$DOTFILES_DIR"* ]]
  [ ! -d "$HOME/config/shell" ]
}

@test "chezmoi symlink mode links static dotfiles to home/" {
  export HOME="$BATS_TEST_TMPDIR/chezmoi-symlink"
  rm -rf "$HOME"; mkdir -p "$HOME"
  env HOME="$HOME" DOTFILES_DIR="$DOTFILES_DIR" "$DOTFILES_DIR/bin/dotfiles" apply
  [ -L "$HOME/.gitconfig" ]
  [ "$(readlink "$HOME/.gitconfig")" = "$DOTFILES_DIR/home/dot_gitconfig" ]
}
