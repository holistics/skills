#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0
IGNORE_REMOVALS="${VALIDATE_LINKS_IGNORE_REMOVALS:-false}"
[ "$IGNORE_REMOVALS" = 1 ] && IGNORE_REMOVALS=true

for arg in "$@"; do
  [ "$arg" = "--ignore-removals" ] && IGNORE_REMOVALS=true
done

# Detect removed .link files
removed_links=()
while IFS= read -r deleted; do
  removed_links+=("$deleted")
done < <(git -C "$REPO_ROOT" diff --name-only --diff-filter=D HEAD -- '*.link' 2>/dev/null | grep '\.link$' || true)

if [ "${#removed_links[@]}" -gt 0 ]; then
  for f in "${removed_links[@]}"; do
    echo "WARNING: .link file removed: $f"
    WARNINGS=$((WARNINGS + 1))
  done
  echo ""

  if [ "$IGNORE_REMOVALS" = false ]; then
    # Git hooks don't get the terminal on stdin, so ask through /dev/tty.
    if ! { : < /dev/tty; } 2>/dev/null; then
      echo "Aborted: no terminal to confirm the removal."
      echo "If it's intended, re-run with VALIDATE_LINKS_IGNORE_REMOVALS=1 (e.g. VALIDATE_LINKS_IGNORE_REMOVALS=1 git commit ...)."
      exit 1
    fi
    read -r -p "Proceed with removed links? [y/N] " reply < /dev/tty
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 1
    fi
  fi
fi

# Validate contents of each linked directory against its source
while IFS= read -r -d '' link_file; do
  dest_dir="$(dirname "$link_file")"
  source_rel="$(cat "$link_file" | tr -d '[:space:]')"
  source_dir="$REPO_ROOT/$source_rel"

  if [ ! -d "$source_dir" ]; then
    echo "ERROR: source not found: $source_rel (referenced from ${link_file#"$REPO_ROOT/"})"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if ! diff -rq --exclude='.link' "$source_dir" "$dest_dir" > /dev/null 2>&1; then
    echo "ERROR: out of sync: ${dest_dir#"$REPO_ROOT/"} <- $source_rel"
    echo "       Run 'pnpm sync-links' to fix."
    ERRORS=$((ERRORS + 1))
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
