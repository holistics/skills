#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

# Warn about .link files deleted in the working tree or staging area
while IFS= read -r deleted; do
  echo "WARNING: .link file removed — run 'pnpm sync-links' or restore it: $deleted"
  ((WARNINGS++))
done < <(git -C "$REPO_ROOT" diff --name-only HEAD -- '*.link' 2>/dev/null | grep '\.link$' || true)

# Validate contents of each linked directory against its source
while IFS= read -r -d '' link_file; do
  dest_dir="$(dirname "$link_file")"
  source_rel="$(cat "$link_file" | tr -d '[:space:]')"
  source_dir="$REPO_ROOT/$source_rel"

  if [ ! -d "$source_dir" ]; then
    echo "ERROR: source not found: $source_rel (referenced from ${link_file#"$REPO_ROOT/"})"
    ((ERRORS++))
    continue
  fi

  if ! diff -rq --exclude='.link' "$source_dir" "$dest_dir" > /dev/null 2>&1; then
    echo "ERROR: out of sync: ${dest_dir#"$REPO_ROOT/"} <- $source_rel"
    echo "       Run 'pnpm sync-links' to fix."
    ((ERRORS++))
  else
    echo "OK: ${dest_dir#"$REPO_ROOT/"} <- $source_rel"
  fi
done < <(find "$REPO_ROOT" -name '.link' -not -path '*/node_modules/*' -print0)

echo ""
[ "$WARNINGS" -gt 0 ] && echo "$WARNINGS warning(s)."
if [ "$ERRORS" -gt 0 ]; then
  echo "$ERRORS error(s). Validation failed."
  exit 1
fi
echo "All links valid."
