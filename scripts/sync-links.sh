#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINKS_FILE="$REPO_ROOT/links.txt"

sync_link() {
  local dest_rel="$1" source_rel="$2"
  local dest_dir="$REPO_ROOT/$dest_rel" source_dir="$REPO_ROOT/$source_rel"

  if [ ! -e "$source_dir" ]; then
    echo "ERROR: source not found: $source_rel (listed for $dest_rel in links.txt)"
    exit 1
  fi

  echo "Syncing $dest_rel <- $source_rel"
  rm -rf "$dest_dir"
  mkdir -p "$(dirname "$dest_dir")"
  cp -r "$source_dir" "$dest_dir"
}

# Optional argument: sync only the copy at this path.
only="${1:-}"
only="${only#"$REPO_ROOT/"}"
only="${only%/}"
found=false

while read -r dest_rel arrow source_rel; do
  [[ -z "$dest_rel" || "$dest_rel" == \#* ]] && continue
  if [ "$arrow" != "<-" ] || [ -z "$source_rel" ]; then
    echo "ERROR: bad line in links.txt: $dest_rel $arrow $source_rel"
    exit 1
  fi
  if [ -z "$only" ] || [ "$only" = "$dest_rel" ]; then
    sync_link "$dest_rel" "$source_rel"
    found=true
  fi
done < "$LINKS_FILE"

if [ -n "$only" ] && [ "$found" = false ]; then
  echo "ERROR: $only is not listed in links.txt"
  exit 1
fi

echo ""
echo "All links synced."
