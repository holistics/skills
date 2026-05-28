#!/usr/bin/env bash
# Discover and run all *.test.sh files under tests/. Exits non-zero if any
# file fails or no tests are found.

set -uo pipefail

cd "$(dirname "$0")/.."

failed=0
total=0

while IFS= read -r -d '' f; do
  total=$((total + 1))
  echo
  echo "=== $f ==="
  bash "$f" || failed=$((failed + 1))
done < <(find tests -type f -name '*.test.sh' -print0 2>/dev/null | sort -z)

echo
if [ "$total" -eq 0 ]; then
  echo "No tests found under tests/."
  exit 1
fi
if [ "$failed" -eq 0 ]; then
  printf 'All %d test file(s) passed.\n' "$total"
else
  printf '%d of %d test file(s) failed.\n' "$failed" "$total"
  exit 1
fi
