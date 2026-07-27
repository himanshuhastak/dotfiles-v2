#!/usr/bin/env bash
# betterleaks (betterleaks/betterleaks) — secrets scanner; the actively
# maintained successor to gitleaks (same authors). Assets use x64 / arm64 and
# include the version in the filename, so resolve the latest tag first.
# Not yet installable via aqua: it's in the aqua-registry now, but postdates
# the registry ref pinned in aqua.yaml (v4.338.0). Revisit once that's bumped.
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
have betterleaks && {
  skip betterleaks
  exit 0
}
case "$(uname -m)" in
  x86_64 | amd64) a=x64 ;;
  aarch64 | arm64) a=arm64 ;;
  *)
    warn "betterleaks: unsupported arch $(uname -m)"
    exit 1
    ;;
esac
tag="$(gh_latest_tag betterleaks/betterleaks)" || {
  warn "betterleaks: no version"
  exit 1
}
ver="${tag#v}"
download_url betterleaks \
  "https://github.com/betterleaks/betterleaks/releases/download/$tag/betterleaks_${ver}_linux_${a}.tar.gz" \
  betterleaks
