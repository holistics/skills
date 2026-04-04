#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sync_link() {
  local link_file="$1"
  local dest_dir source_rel source_dir
  dest_dir="$(dirname "$link_file")"
  source_rel="$(cat "$link_file" | tr -d '[:space:]')"
  source_dir="$REPO_ROOT/$source_rel"

  if [ ! -e "$source_dir" ]; then
    echo "ERROR: source not found: $source_rel (referenced from $link_file)"
    exit 1
  fi

  echo "Syncing ${dest_dir#"$REPO_ROOT/"} <- $source_rel"
  rm -rf "$dest_dir"
  cp -r "$source_dir" "$dest_dir"
  echo "$source_rel" > "$dest_dir/.link"
}

if [ $# -eq 1 ]; then
  arg="$1"
  [[ "$arg" != */.link ]] && arg="$arg/.link"
  sync_link "$arg"
else
  while IFS= read -r -d '' link_file; do
    sync_link "$link_file"
  done < <(find "$REPO_ROOT" -name '.link' -print0)
fi

echo ""
echo "All links synced."
