#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

while IFS= read -r -d '' link; do
  # Check not broken
  if ! target="$(readlink -f "$link" 2>/dev/null)" || [ ! -e "$target" ]; then
    echo "BROKEN: $link"
    ((ERRORS++))
    continue
  fi

  # Check target is within the repo
  if [[ "$target" != "$REPO_ROOT"/* ]]; then
    echo "OUTSIDE REPO: $link -> $target"
    ((ERRORS++))
    continue
  fi

  echo "OK: ${link#"$REPO_ROOT/"} -> ${target#"$REPO_ROOT/"}"
done < <(find "$REPO_ROOT" -type l -print0)

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Found $ERRORS symlink error(s)."
  exit 1
fi

echo ""
echo "All symlinks OK."
