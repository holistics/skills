#!/usr/bin/env sh
# PostToolUse hook: validate AML files with the Holistics CLI after Write/Edit.
# Always non-blocking: emits findings as additionalContext (a warning the
# agent sees) and exits 0. Silent on non-AML files and on successful
# validation.

set -u

emit_warning() {
  esc=$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS=""} {if(NR>1) printf "\\n"; print}')
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
}

input=$(cat)
file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

case "$file" in
  *.aml) ;;
  *) exit 0 ;;
esac

if ! command -v holistics >/dev/null 2>&1; then
  emit_warning "AML file edited but the \`holistics\` CLI is not installed, so $file was not validated. Use the \`holistics-development:setup-holistics-cli\` skill to install it."
  exit 0
fi

out=$(holistics aml validate "$file" 2>&1)
rc=$?
if [ "$rc" -ne 0 ]; then
  msg=$(printf '%s\n%s' "AML validation failed for $file:" "$out")
  emit_warning "$msg"
fi
exit 0
