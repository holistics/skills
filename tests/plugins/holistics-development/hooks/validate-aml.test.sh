#!/usr/bin/env bash
# Tests for plugins/holistics-development/hooks/validate-aml.sh.
# Mocks `holistics` on PATH so tests are deterministic and don't require the
# real CLI in CI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
HOOK="$REPO_ROOT/plugins/holistics-development/hooks/validate-aml.sh"

if [ ! -f "$HOOK" ]; then
  echo "Hook script not found at $HOOK" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "jq is required for these tests" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf '  ok: %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL: %s\n' "$1"; }

assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"
  else bad "$1 (expected '$2', got '$3')"; fi
}

assert_empty() {
  if [ -z "$2" ]; then ok "$1"
  else bad "$1 (expected empty, got: $2)"; fi
}

assert_contains() {
  if printf '%s' "$3" | grep -qF -- "$2"; then ok "$1"
  else bad "$1 (expected to contain '$2', got: $3)"; fi
}

assert_json_valid() {
  if printf '%s' "$2" | jq empty >/dev/null 2>&1; then ok "$1"
  else bad "$1 (invalid JSON: $2)"; fi
}

# Mock holistics binaries.
mkdir -p "$TMP/bin-good" "$TMP/bin-bad"
cat > "$TMP/bin-good/holistics" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
cat > "$TMP/bin-bad/holistics" <<'EOF'
#!/usr/bin/env sh
# Emit chars that exercise JSON escaping: quote, backslash, newline.
printf 'Compilation error:\nLine 1, col 7: Property "type" is missing.\nBack\\slash here.\n'
exit 1
EOF
chmod +x "$TMP/bin-good/holistics" "$TMP/bin-bad/holistics"

PAYLOAD_AML='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.aml"}}'
PAYLOAD_PY='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.py"}}'
PAYLOAD_WRITE_AML='{"tool_name":"Write","tool_input":{"file_path":"/tmp/y.aml","content":"..."}}'

echo "Test 1: non-AML file → silent, exit 0"
set +e; out=$(printf '%s' "$PAYLOAD_PY" | PATH="$TMP/bin-good:$PATH" sh "$HOOK"); rc=$?; set -e
assert_eq "exit code" 0 "$rc"
assert_empty "stdout" "$out"

echo "Test 2: AML file via Edit, valid → silent, exit 0"
set +e; out=$(printf '%s' "$PAYLOAD_AML" | PATH="$TMP/bin-good:$PATH" sh "$HOOK"); rc=$?; set -e
assert_eq "exit code" 0 "$rc"
assert_empty "stdout" "$out"

echo "Test 3: AML file via Write, valid → silent, exit 0"
set +e; out=$(printf '%s' "$PAYLOAD_WRITE_AML" | PATH="$TMP/bin-good:$PATH" sh "$HOOK"); rc=$?; set -e
assert_eq "exit code" 0 "$rc"
assert_empty "stdout" "$out"

echo "Test 4: AML file, validation fails → warning emitted, exit 0"
set +e; out=$(printf '%s' "$PAYLOAD_AML" | PATH="$TMP/bin-bad:$PATH" sh "$HOOK"); rc=$?; set -e
assert_eq "exit code" 0 "$rc"
assert_contains "stdout has additionalContext" '"additionalContext"' "$out"
assert_contains "stdout mentions failure" 'AML validation failed' "$out"
assert_contains "stdout includes error text" 'Compilation error' "$out"
assert_json_valid "stdout is well-formed JSON" "$out"

echo "Test 5: AML file, holistics missing → install prompt, exit 0"
set +e; out=$(printf '%s' "$PAYLOAD_AML" | env -i PATH=/usr/bin:/bin sh "$HOOK"); rc=$?; set -e
assert_eq "exit code" 0 "$rc"
assert_contains "stdout mentions setup-holistics-cli" 'setup-holistics-cli' "$out"
assert_json_valid "stdout is well-formed JSON" "$out"

echo "Test 6: JSON escaping round-trips quotes, backslashes, newlines"
out=$(printf '%s' "$PAYLOAD_AML" | PATH="$TMP/bin-bad:$PATH" sh "$HOOK")
parsed=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')
assert_contains "quote preserved" 'Property "type"' "$parsed"
assert_contains "backslash preserved" 'Back\slash' "$parsed"
assert_contains "newline preserved" "$(printf 'Compilation error:\nLine 1')" "$parsed"

echo
if [ "$FAIL" -eq 0 ]; then
  printf 'All %d checks passed.\n' "$PASS"
else
  printf '%d failed, %d passed.\n' "$FAIL" "$PASS"
  exit 1
fi
