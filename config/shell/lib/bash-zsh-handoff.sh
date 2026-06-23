# config/shell/lib/bash-zsh-handoff.sh — interactive bash → clean login zsh.
# Sourced from stowed ~/.bashrc. X11 is fixed in $ZDOTDIR/.zprofile, not here.

dotfiles_bash_zsh_handoff() {
  local _stowed="${1:-}"
  local _resolve _zsh _user _v
  local -a _env
  local -a _fwd=(
    LANG LC_ALL DISPLAY XAUTHORITY
    SSH_CONNECTION SSH_CLIENT
    LSB_JOBID
    DOTFILES_ZSH_LOGIN
  )

  _resolve="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/resolve-dotfiles-dir.sh"
  DOTFILES_DIR=
  # shellcheck disable=SC1090
  [[ -r "$_resolve" ]] && . "$_resolve" "$_stowed"

  # shellcheck disable=SC1090
  [[ -r "${DOTFILES_DIR:-}/config/shell/lib/dotfiles-zsh.sh" ]] && \
    . "${DOTFILES_DIR}/config/shell/lib/dotfiles-zsh.sh"

  _zsh=""
  type dotfiles_self_zsh_bin >/dev/null 2>&1 && _zsh="$(dotfiles_self_zsh_bin)" || true
  [[ -z "$_zsh" && -x "${DOTFILES_DIR:-}/var/tools/bin/zsh" ]] && \
    _zsh="$DOTFILES_DIR/var/tools/bin/zsh"
  if [[ -z "$_zsh" ]]; then
    _zsh="$(command -v zsh 2>/dev/null || echo /usr/bin/zsh)"
    [[ -x "$_zsh" ]] || {
      printf 'dotfiles: zsh not found (install tools: ./install.sh)\n' >&2
      return 1
    }
  fi

  _user="${USER:-$(id -un)}"
  _env=( -i
    "HOME=$HOME"
    "USER=$_user"
    "LOGNAME=${LOGNAME:-$_user}"
    "TERM=${TERM:-xterm-256color}"
    "SHELL=$_zsh"
    "DOTFILES_DIR=${DOTFILES_DIR:-}"
  )
  for _v in "${_fwd[@]}"; do
    [[ -n "${!_v:-}" ]] && _env+=( "$_v=${!_v}" )
  done

  case "${DOTFILES_ZSH_LOGIN:-1}" in
    0|no|nonlogin|non-login|false|FALSE)
      exec env "${_env[@]}" "$_zsh"
      ;;
    *)
      exec env "${_env[@]}" "$_zsh" -l
      ;;
  esac
}
