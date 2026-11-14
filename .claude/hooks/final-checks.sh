#!/usr/bin/env bash
# Stop hook: at the end of a turn, runs the deterministic checks on what the turn touched.
#   - Swift: lint of the changed files; build and tests of every Swift package that contains one;
#     build of the app when the Xcode project exists and full Xcode is installed
#   - workflows: actionlint and zizmor; shell scripts: shellcheck (each only if installed)
# On failure it blocks, handing the output back so the agent fixes it before stopping. It blocks at most
# once per turn (stop_hook_active), so a check that cannot pass does not loop.
set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# Working tree changes plus the marker written by format.sh: the marker covers what the turn already
# committed. Deleted files stay in the list on purpose: the package that held them must still build.
marker="$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null)/claude-edited-files.txt"
changed=$(
  {
    git -C "$root" status --porcelain 2>/dev/null | awk '{print $NF}'
    [ -f "$marker" ] && cat "$marker"
  } | sort -u
)
[ -n "$changed" ] || exit 0

swift_files=""
packages=""
app_touched=0
workflows=""
scripts=""

# Nearest directory containing a Package.swift, walking up from a repository-relative path.
package_of() {
  local dir
  dir=$(dirname "$1")
  while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    [ -f "$root/$dir/Package.swift" ] && { printf '%s' "$dir"; return; }
    dir=$(dirname "$dir")
  done
  [ -f "$root/Package.swift" ] && printf '.'
}

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  case "$rel" in
    *.swift | Package.resolved | */Package.resolved)
      case "$rel" in *.swift) [ -f "$root/$rel" ] && swift_files="$swift_files $root/$rel" ;; esac
      pkg=$(package_of "$rel")
      if [ -n "$pkg" ]; then
        case " $packages " in *" $pkg "*) ;; *) packages="$packages $pkg" ;; esac
      fi
      ;;
  esac
  case "$rel" in
    App/*) app_touched=1 ;;
    .github/workflows/*.yml | .github/workflows/*.yaml) [ -f "$root/$rel" ] && workflows="$workflows $root/$rel" ;;
    *.sh) [ -f "$root/$rel" ] && scripts="$scripts $root/$rel" ;;
  esac
done <<EOF
$changed
EOF

fail=""

record_fail() {
  fail="$fail

### $1
$(printf '%s' "$2" | tail -n 60)"
}

if [ -n "$swift_files" ]; then
  # shellcheck disable=SC2086 # one argument per path
  out=$(swift format lint --strict --configuration "$root/.swift-format" $swift_files 2>&1) || record_fail "swift format lint" "$out"
fi

for pkg in $packages; do
  if ! out=$(cd "$root/$pkg" && swift build 2>&1); then
    record_fail "swift build ($pkg)" "$out"
    continue
  fi
  out=$(cd "$root/$pkg" && swift test 2>&1) || record_fail "swift test ($pkg)" "$out"
done

# The app needs full Xcode; with only the Command Line Tools xcodebuild fails, and that is a setup gap,
# not a defect of the turn, so it is skipped rather than reported.
if [ "$app_touched" = 1 ] && [ -d "$root/App/Verba.xcodeproj" ] && xcodebuild -version >/dev/null 2>&1; then
  out=$(xcodebuild -project "$root/App/Verba.xcodeproj" -scheme Verba -destination 'platform=macOS' -quiet build 2>&1) || record_fail "xcodebuild (Verba)" "$out"
fi

if [ -n "$workflows" ] && command -v actionlint >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  out=$(cd "$root" && actionlint $workflows 2>&1) || record_fail "actionlint" "$out"
fi
if [ -n "$workflows" ] && command -v zizmor >/dev/null 2>&1; then
  # Offline: the online audits need a GitHub token and CI runs them anyway.
  # shellcheck disable=SC2086
  out=$(cd "$root" && zizmor --offline --no-progress $workflows 2>&1) || record_fail "zizmor" "$out"
fi

if [ -n "$scripts" ] && command -v shellcheck >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  out=$(shellcheck $scripts 2>&1) || record_fail "shellcheck" "$out"
fi

if [ -n "$fail" ]; then
  reason="The end-of-turn checks failed. Fix them and re-run the failing check yourself before stopping (this hook does not re-check in the same turn):${fail}"
  jq -n --arg r "$reason" '{decision: "block", reason: $r}'
fi

exit 0
