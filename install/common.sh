# install/common.sh — shared helpers for dotfiles install scripts.
# Source from a step script:  source "$(dirname "$0")/../common.sh"
# (tool scripts live in install/tools/, same relative depth: ../common.sh)

[ -n "${DOTFILES_COMMON_SOURCED:-}" ] && return 0
DOTFILES_COMMON_SOURCED=1

# --- guaranteed base PATH (very first step) ----------------------------------
# Make sure the core system utilities (curl/grep/sed/tar/...) are ALWAYS
# reachable, even if this installer is invoked with a minimal or empty PATH
# (cron, CI, `env -i`, a broken login). Appended — never prepended — so our own
# var/tools/bin still takes precedence once init_tools_dir runs.
for _p in /usr/bin /bin /usr/sbin /sbin /usr/local/bin; do
  [ -d "$_p" ] || continue
  case ":$PATH:" in *":$_p:"*) ;; *) PATH="${PATH:+$PATH:}$_p" ;; esac
done
export PATH
unset _p

# --- paths -------------------------------------------------------------------
# Repo root is one level up from install/. Layout:
#   config/{stow,shell}   tracked config + shell framework
#   install/{steps,tools} this installer
#   var/{tools,vendor,cache}  generated, gitignored (self-owned; never NFS-reuse)
DOTFILES="$(cd "${DOTFILES:-$(dirname "${BASH_SOURCE[0]}")/..}" && pwd)"
STOW_DIR="$DOTFILES/config/stow"
STOW="$DOTFILES/install/bin/stow"
TOOLS_DIR="$DOTFILES/var/tools"     # self-owned; NEVER reuse system/NFS tools
BIN="$TOOLS_DIR/bin"
CACHE="$DOTFILES/var/cache"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"

# --- pretty logging ----------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✔\033[0m %s\n' "$*"; }
skip() { printf '\033[1;33m-\033[0m %s (skipped)\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }

# --- tools dir ---------------------------------------------------------------
init_tools_dir() {
  mkdir -p "$BIN" "$CACHE"
  export TOOLS_DIR BIN
  case ":$PATH:" in *":$BIN:"*) ;; *) PATH="$BIN:$PATH" ;; esac
  export PATH
}

# have NAME — is the tool already installed in our tools dir (or on PATH)?
have() { [ -x "$BIN/$1" ] || command -v "$1" >/dev/null 2>&1; }

# --- arch helpers ------------------------------------------------------------
detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo x86_64 ;;
    aarch64|arm64) echo aarch64 ;;
    *) warn "unsupported arch $(uname -m)"; return 1 ;;
  esac
}
go_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    *) warn "unsupported arch $(uname -m)"; return 1 ;;
  esac
}

# --- github helpers ----------------------------------------------------------
# gh_latest_tag REPO -> prints latest release tag (e.g. v1.2.3 or 1.2.3)
# Prefers the /releases/latest redirect (github.com, NOT rate-limited);
# falls back to the API only if that fails.
gh_latest_tag() {
  local repo=$1 url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
        "https://github.com/$repo/releases/latest" 2>/dev/null || true)"
  case "$url" in
    */releases/tag/*) printf '%s\n' "${url##*/tag/}"; return 0 ;;
  esac
  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
    | grep -m1 '"tag_name"' | cut -d'"' -f4
}

# download_url NAME URL BINNAME [PATHHINT]
# Fetches URL, extracts (or treats as raw binary), installs BINNAME into $BIN.
# PATHHINT (optional) prefers a binary whose path contains that substring
# (used when an archive ships several arch builds, e.g. broot).
download_url() {
  local name=$1 url=$2 binname=$3 hint=${4:-} tmp found
  command -v curl >/dev/null 2>&1 || { warn "curl required for $name"; return 1; }
  mkdir -p "$BIN" "$CACHE"
  tmp="$(mktemp -d "$CACHE/${name}.XXXXXX")"
  log "Installing $name"
  (
    cd "$tmp"
    curl -fsSL --retry 3 --connect-timeout 20 -o file "$url" || exit 1
    case "$url" in
      *.tar.gz|*.tgz) tar -xzf file ;;
      *.tar.xz)       tar -xJf file ;;
      *.tar.bz2)      tar -xjf file ;;
      *.zip)          unzip -q file ;;
      *)              cp file "$binname"; chmod +x "$binname" ;;
    esac
    found=""
    [ -n "$hint" ] && found="$(find . -type f -path "*$hint*" -name "$binname" 2>/dev/null | head -n1)"
    [ -n "$found" ] || found="$(find . -type f -name "$binname" -perm -u+x 2>/dev/null | head -n1)"
    [ -n "$found" ] || found="$(find . -type f -name "$binname" 2>/dev/null | head -n1)"
    [ -n "$found" ] || { warn "$name: '$binname' not found in download"; exit 1; }
    install -m 0755 "$found" "$BIN/$binname"
  ) || { rm -rf "$tmp" 2>/dev/null || true; warn "$name: install failed"; return 1; }
  rm -rf "$tmp" 2>/dev/null || true
  ok "$name -> $BIN/$binname"
}

# install_tool NAME REPO ASSET [BINNAME] [PATHHINT]
# ASSET may contain placeholders: {tag} {ver} {arch} {goarch}
#   {tag} = release tag (v1.2.3),  {ver} = tag without leading v
#   {arch}=x86_64|aarch64,  {goarch}=amd64|arm64
# If ASSET needs no version, the GitHub /latest/download/ redirect is used
# (no API call). Otherwise the latest tag is resolved first.
install_tool() {
  local name=$1 repo=$2 asset=$3 binname=${4:-$1} hint=${5:-} arch goarch url tag ver
  if have "$name"; then skip "$name"; return 0; fi
  arch="$(detect_arch)"  || return 1
  goarch="$(go_arch)"    || return 1
  asset="${asset//\{arch\}/$arch}"
  asset="${asset//\{goarch\}/$goarch}"
  hint="${hint//\{arch\}/$arch}"
  hint="${hint//\{goarch\}/$goarch}"
  case "$asset" in
    *'{tag}'*|*'{ver}'*)
      tag="$(gh_latest_tag "$repo")"
      [ -n "$tag" ] || { warn "$name: cannot resolve latest version of $repo"; return 1; }
      ver="${tag#v}"
      asset="${asset//\{tag\}/$tag}"
      asset="${asset//\{ver\}/$ver}"
      url="https://github.com/$repo/releases/download/$tag/$asset"
      ;;
    *)
      url="https://github.com/$repo/releases/latest/download/$asset"
      ;;
  esac
  download_url "$name" "$url" "$binname" "$hint"
}

# ensure_rust — rustc+cargo on PATH for source builds (taskwarrior 3.x, pipr, …).
# Fast no-op when already installed; otherwise delegates to install/tools/rust.sh.
ensure_rust() {
  init_tools_dir
  local prefix="$TOOLS_DIR/pkg/rust"
  case ":${PATH:-}:" in *":$prefix/bin:"*) ;; *)
    PATH="$prefix/bin:${PATH:-}"; export PATH ;;
  esac
  if command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
    return 0
  fi
  if [ -x "$prefix/bin/rustc" ] && [ -x "$prefix/bin/cargo" ]; then
    return 0
  fi
  bash "$DOTFILES/install/tools/rust.sh" --ensure
}

# build_from_source NAME REPO ASSET_TMPL BINNAME [extra cmake args...]
# For tools with no prebuilt static binary (e.g. taskwarrior, timewarrior).
# Downloads a release *source* tarball, builds with cmake into
# $TOOLS_DIR/pkg/<name>, then symlinks <binname> into $BIN. Best-effort:
# needs cmake + make + a C++ compiler (taskwarrior 3.x also needs cargo).
build_from_source() {
  local name=$1 repo=$2 tmpl=$3 binname=$4; shift 4
  if have "$name"; then skip "$name"; return 0; fi
  command -v cmake >/dev/null 2>&1 || { warn "$name: cmake required (source build)"; return 1; }
  command -v make  >/dev/null 2>&1 || { warn "$name: make required (source build)";  return 1; }
  local tag ver asset url prefix tmp dir
  tag="$(gh_latest_tag "$repo")" || true
  [ -n "$tag" ] || { warn "$name: cannot resolve latest version of $repo"; return 1; }
  ver="${tag#v}"
  asset="${tmpl//\{tag\}/$tag}"; asset="${asset//\{ver\}/$ver}"
  url="https://github.com/$repo/releases/download/$tag/$asset"
  prefix="$TOOLS_DIR/pkg/$name"
  tmp="$(mktemp -d "$CACHE/$name.XXXXXX")"
  log "Building $name $ver from source (this can take a while)"
  (
    cd "$tmp"
    curl -fL --retry 3 --connect-timeout 20 -o src.tar.gz "$url" || exit 1
    tar -xzf src.tar.gz
    dir="$(find . -maxdepth 1 -mindepth 1 -type d | head -n1)"
    cd "$dir" || exit 1
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" "$@" . || exit 1
    make -j"$(nproc 2>/dev/null || echo 2)" || exit 1
    make install || exit 1
  ) || { rm -rf "$tmp" 2>/dev/null || true; warn "$name: source build failed"; return 1; }
  rm -rf "$tmp" 2>/dev/null || true
  [ -x "$prefix/bin/$binname" ] && ln -sf "$prefix/bin/$binname" "$BIN/$binname"
  ok "$name -> $BIN/$binname"
}

# discover_packages — every non-empty dir under stow/.
discover_packages() {
  local d
  for d in "$STOW_DIR"/*/; do
    [ -d "$d" ] || continue
    find "$d" -mindepth 1 \( -type f -o -type l \) -print -quit | grep -q . || continue
    basename "$d"
  done
}
