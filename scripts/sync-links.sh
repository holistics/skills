#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS= read -r -d '' link_file; do
  dest_dir="$(dirname "$link_file")"
  source_rel="$(cat "$link_file" | tr -d '[:space:]')"
  source_dir="$REPO_ROOT/$source_rel"

  if [ ! -e "$source_dir" ]; then
    echo "ERROR: source not found: $source_rel (referenced from $link_file)"
    exit 1
  fi

  echo "Syncing ${dest_dir#"$REPO_ROOT/"} <- $source_rel"
  # Wipe dest and replace with a fresh copy of source, then restore .link
  rm -rf "$dest_dir"
  cp -r "$source_dir" "$dest_dir"
  echo "$source_rel" > "$dest_dir/.link"
done < <(find "$REPO_ROOT" -name '.link' -print0)

echo ""
echo "All links synced."
