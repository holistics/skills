#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ $# -eq 0 ]; then
  # Pick source from holistics-common
  echo "Select source:"
  mapfile -t sources < <(find "$REPO_ROOT/plugins/holistics-common" -mindepth 2 -maxdepth 2 -type d | sed "s|$REPO_ROOT/||" | sort)
  select SOURCE_REL in "${sources[@]}"; do
    [ -n "$SOURCE_REL" ] && break
    echo "Invalid selection."
  done

  # Pick destination plugin (exclude holistics-common)
  echo ""
  echo "Select destination plugin:"
  mapfile -t plugins < <(find "$REPO_ROOT/plugins" -mindepth 1 -maxdepth 1 -type d -not -name 'holistics-common' | sed "s|$REPO_ROOT/||" | sort)
  select DEST_PLUGIN in "${plugins[@]}"; do
    [ -n "$DEST_PLUGIN" ] && break
    echo "Invalid selection."
  done
elif [ $# -eq 2 ]; then
  SOURCE_REL="$1"
  DEST_PLUGIN="$2"
else
  echo "Usage: $0 [<source-path> <dest-plugin>]"
  echo "  e.g. $0 plugins/holistics-common/skills/use-existing-viz plugins/holistics-development"
  exit 1
fi

SOURCE_DIR="$REPO_ROOT/$SOURCE_REL"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "ERROR: source directory not found: $SOURCE_REL"
  exit 1
fi

# Mirror the path structure: strip the source plugin prefix (first two path components)
SOURCE_PLUGIN="$(echo "$SOURCE_REL" | cut -d'/' -f1-2)"
REMAINDER="${SOURCE_REL#"$SOURCE_PLUGIN/"}"
DEST_DIR="$REPO_ROOT/$DEST_PLUGIN/$REMAINDER"

if [ -e "$DEST_DIR" ]; then
  echo "ERROR: destination already exists: $DEST_PLUGIN/$REMAINDER"
  exit 1
fi

mkdir -p "$DEST_DIR"
cp -r "$SOURCE_DIR"/. "$DEST_DIR/"
echo "$SOURCE_REL" > "$DEST_DIR/.link"

echo "Created $DEST_PLUGIN/$REMAINDER <- $SOURCE_REL"

"$REPO_ROOT/scripts/sync-links.sh" "$DEST_DIR"
