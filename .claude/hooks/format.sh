#!/usr/bin/env bash
# PostToolUse hook: formats the file just edited and records it in this session's marker, read by
# final-checks.sh at the end of the turn. Never blocks: always exits 0 and ignores tool failures.
set -u

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# Physical path: through a symlink the same file would otherwise be recorded twice, or outside its repository.
dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd -P) || exit 0
file="$dir/$(basename "$file")"

# One marker per session, holding absolute paths: two sessions on the same checkout do not empty each
# other's list, and a session editing another worktree records where the file really is.
# The id becomes part of a path: anything but a plain id is skipped.
if [ -n "$session" ] && [ -z "${session//[A-Za-z0-9-]/}" ]; then
  printf '%s\n' "$file" >>"${TMPDIR:-/tmp}/verba-claude-edited-$session" 2>/dev/null || true
fi

case "$file" in
  *.swift)
    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
    swift format format --in-place --configuration "$root/.swift-format" "$file" >/dev/null 2>&1 || true
    ;;
esac

exit 0
