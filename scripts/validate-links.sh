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

LINKS_FILE="$REPO_ROOT/links.txt"

# Lines of links.txt that are entries, not comments or blanks.
entries() { grep -vE '^[[:space:]]*(#|$)' || true; }

# Detect links removed from links.txt since the last commit
removed_links=()
while IFS= read -r removed; do
  removed_links+=("$removed")
done < <(comm -23 \
  <(git -C "$REPO_ROOT" show HEAD:links.txt 2>/dev/null | entries | sort) \
  <(entries < "$LINKS_FILE" | sort))

if [ "${#removed_links[@]}" -gt 0 ]; then
  for f in "${removed_links[@]}"; do
    echo "WARNING: link removed: $f"
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
while read -r dest_rel arrow source_rel; do
  source_dir="$REPO_ROOT/$source_rel"
  dest_dir="$REPO_ROOT/$dest_rel"

  if [ "$arrow" != "<-" ] || [ -z "$source_rel" ]; then
    echo "ERROR: bad line in links.txt: $dest_rel $arrow $source_rel"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if [ ! -d "$source_dir" ]; then
    echo "ERROR: source not found: $source_rel (listed for $dest_rel in links.txt)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if ! diff -rq "$source_dir" "$dest_dir" > /dev/null 2>&1; then
    echo "ERROR: out of sync: $dest_rel <- $source_rel"
    echo "       Run 'pnpm sync-links' to fix."
    ERRORS=$((ERRORS + 1))
  else
    echo "OK: $dest_rel <- $source_rel"
  fi
done < <(entries < "$LINKS_FILE")

echo ""
[ "$WARNINGS" -gt 0 ] && echo "$WARNINGS warning(s)."
if [ "$ERRORS" -gt 0 ]; then
  echo "$ERRORS error(s). Validation failed."
  exit 1
fi
echo "All links valid."
