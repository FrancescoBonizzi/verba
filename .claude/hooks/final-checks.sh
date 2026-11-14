#!/usr/bin/env bash
# Stop hook: at the end of a turn, runs the deterministic checks on the files this session edited with
# Edit/Write during the turn (format.sh records them; files created through Bash are not seen).
#   - Swift: lint of the edited files; build and tests of every Swift package that contains one; build of
#     the app when App/ or a package under Packages/ changed and the Xcode project exists
#   - workflows: actionlint and zizmor; shell scripts: shellcheck (each only if installed)
# On failure it blocks, handing the output back so the agent fixes it before stopping. It blocks at most
# once per turn (stop_hook_active), so a check that cannot pass does not loop.
set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
# The id becomes part of a path: anything but a plain id is refused.
case "$session" in "" | *[!A-Za-z0-9-]*) exit 0 ;; esac
marker="${TMPDIR:-/tmp}/verba-claude-edited-$session"
[ -s "$marker" ] || exit 0

swift_files=()
workflows=()
scripts=()
# Newline-separated, deduplicated with sort -u below: bash 3.2 has no associative arrays.
package_list=""
app_list=""

# Nearest directory containing a Package.swift, walking up from a file to its repository root.
package_of() {
  local dir root=$2
  dir=$(dirname "$1")
  while :; do
    [ -f "$dir/Package.swift" ] && { printf '%s' "$dir"; return; }
    if [ "$dir" = "$root" ] || [ "$dir" = "/" ]; then return; fi
    dir=$(dirname "$dir")
  done
}

while IFS= read -r file; do
  [ -n "$file" ] || continue
  # A file deleted later in the turn still counts: the package that held it must still build.
  root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || continue
  rel=${file#"$root"/}
  case "$rel" in
    *.swift | Package.resolved | */Package.resolved)
      case "$rel" in *.swift) [ -f "$file" ] && swift_files+=("$file") ;; esac
      pkg=$(package_of "$file" "$root")
      [ -n "$pkg" ] && package_list="$package_list$pkg"$'\n'
      case "$rel" in App/* | Packages/*) app_list="$app_list$root"$'\n' ;; esac
      ;;
    App/*) app_list="$app_list$root"$'\n' ;;
    .github/workflows/*.yml | .github/workflows/*.yaml) [ -f "$file" ] && workflows+=("$file") ;;
    *.sh) [ -f "$file" ] && scripts+=("$file") ;;
  esac
done < <(sort -u "$marker")

packages=()
while IFS= read -r p; do [ -n "$p" ] && packages+=("$p"); done < <(printf '%s' "$package_list" | sort -u)
apps=()
while IFS= read -r p; do [ -n "$p" ] && apps+=("$p"); done < <(printf '%s' "$app_list" | sort -u)

fail=""

# The lines that name the failure first, then the tail: with swift test the failing test's detail comes
# before the summary, and a plain tail would cut it.
record_fail() {
  local detail
  detail=$(printf '%s\n' "$2" | grep -E 'error:|failed|✘' | head -n 40)
  [ -n "$detail" ] || detail=$(printf '%s\n' "$2" | tail -n 60)
  fail="$fail

### $1
$detail"
}

if [ ${#swift_files[@]} -gt 0 ] || [ ${#packages[@]} -gt 0 ]; then
  if ! xcodebuild -version >/dev/null 2>&1; then
    # With only the Command Line Tools swift build and swift test fail on any code: say so once instead
    # of reporting every check as a defect of the turn.
    record_fail "setup" "error: full Xcode is not selected, so the Swift checks cannot run. Install Xcode and run: sudo xcode-select -s /Applications/Xcode.app"
  else
    for f in "${swift_files[@]+"${swift_files[@]}"}"; do
      root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel)
      out=$(swift format lint --strict --configuration "$root/.swift-format" "$f" 2>&1) || record_fail "swift format lint" "$out"
    done
    for pkg in "${packages[@]+"${packages[@]}"}"; do
      if ! out=$(cd "$pkg" && swift build 2>&1); then
        record_fail "swift build ($pkg)" "$out"
        continue
      fi
      out=$(cd "$pkg" && swift test 2>&1) || record_fail "swift test ($pkg)" "$out"
    done
    for root in "${apps[@]+"${apps[@]}"}"; do
      [ -d "$root/App/Verba.xcodeproj" ] || continue
      out=$(xcodebuild -project "$root/App/Verba.xcodeproj" -scheme Verba -destination 'platform=macOS' -quiet build 2>&1) || record_fail "xcodebuild ($root)" "$out"
    done
  fi
fi

for f in "${workflows[@]+"${workflows[@]}"}"; do
  if command -v actionlint >/dev/null 2>&1; then
    out=$(cd "$(dirname "$f")/../.." && actionlint "$f" 2>&1) || record_fail "actionlint" "$out"
  fi
  if command -v zizmor >/dev/null 2>&1; then
    # Offline: the online audits need a GitHub token, and CI runs them anyway.
    out=$(zizmor --offline --no-progress "$f" 2>&1) || record_fail "zizmor" "$out"
  fi
done

if [ ${#scripts[@]} -gt 0 ] && command -v shellcheck >/dev/null 2>&1; then
  out=$(shellcheck "${scripts[@]}" 2>&1) || record_fail "shellcheck" "$out"
fi

if [ -n "$fail" ]; then
  reason="The end-of-turn checks failed. Fix them and re-run the failing check yourself before stopping (this hook does not re-check in the same turn):${fail}"
  jq -n --arg r "$reason" '{decision: "block", reason: $r}'
fi

exit 0
