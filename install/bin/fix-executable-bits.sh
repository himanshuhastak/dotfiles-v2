#!/usr/bin/env bash
# Record +x in git for every tracked shebang script (and chmod the working tree).
# Run after adding new bin/ or install/ scripts: make fix-exec
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

n=0
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  head -1 "$f" 2>/dev/null | grep -q '^#!' || continue
  git update-index --chmod=+x "$f"
  chmod +x "$f"
  n=$((n + 1))
done < <(git ls-files -z)

printf 'fix-exec: %s script(s) marked executable in git and on disk\n' "$n"
