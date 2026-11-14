#!/usr/bin/env bash
# PostToolUse hook: formats the file just edited and records it in the marker of files touched this turn.
# Never blocks: always exits 0 and ignores tool failures (CI's lint is the gate).
set -u

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || exit 0

# Read by final-checks.sh and emptied by the UserPromptSubmit hook. "git status" alone misses work the turn
# already committed: without the marker, a turn that commits would verify nothing.
marker="$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null)/claude-edited-files.txt"
printf '%s\n' "${file#"$root"/}" >>"$marker" 2>/dev/null || true

case "$file" in
  *.swift)
    swift format format --in-place --configuration "$root/.swift-format" "$file" >/dev/null 2>&1 || true
    ;;
esac

exit 0
