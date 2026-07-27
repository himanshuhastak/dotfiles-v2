#!/usr/bin/env bash
# Mark machine-specific profile files as skip-worktree (repo-local, not global).
# Git has no config key for this — update-index must be run per file per clone.
set -uo pipefail
source "$(dirname "$0")/../common.sh"

git_dir="$DOTFILES/.git"
[ -d "$git_dir" ] || { skip "profile-git-local (not a git repo)"; exit 0; }

command -v git >/dev/null 2>&1 || { skip "profile-git-local (git missing)"; exit 0; }

mark_skip_worktree() {
  local rel="$1"
  local path="$DOTFILES/$rel"
  [ -f "$path" ] || return 0
  if git -C "$DOTFILES" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
    if git -C "$DOTFILES" ls-files -v "$rel" 2>/dev/null | grep -q '^S'; then
      ok "skip-worktree already: $rel"
    else
      git -C "$DOTFILES" update-index --skip-worktree "$rel" && ok "skip-worktree: $rel"
    fi
  fi
}

# Machine-specific — local edits should not appear in git status / accidental commits.
mark_skip_worktree local/profile/ssh.local

# Future multi-profile paths (no-op if missing):
for f in local/profiles/*/ssh.local; do
  [ -f "$DOTFILES/$f" ] || continue
  rel="${f#"$DOTFILES/"}"
  mark_skip_worktree "$rel"
done
