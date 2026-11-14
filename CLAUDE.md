# CLAUDE.md

Entry point for AI coding agents. Read this first; [`ROADMAP.md`](ROADMAP.md) says what is being built and why.

## What Verba is

A native macOS app that turns audio and images into text **on the Mac**: voice notes and audio files to
text, screenshots, images and PDFs to text or Markdown. Free, offline, open source (MIT).

- **Nothing the user gives Verba leaves the Mac.** The only network traffic allowed is downloading a model
  from a pinned source (see "Models"). No telemetry, no analytics, no crash reporters, no update pings. A
  change that adds any other network call is a breaking design change: it needs an issue and the
  maintainer's explicit approval first.
- **Few settings, Apple-style UI.** Prefer a good default over an option. A new setting needs a user who
  cannot do without it.
- Target: **macOS 27+, Apple Silicon only.** No compatibility branches for older systems or Intel.

## Layout

The code does not exist yet: milestone M0 in `ROADMAP.md` creates it with this shape. Update this section
in the same PR that changes it.

- `App/` — the Xcode project (`Verba.xcodeproj`) with synchronized folders: the app target and the Finder
  Quick Action extension. A thin shell: UI, permissions, wiring.
- `Packages/VerbaKit/` — a local Swift package with all the logic (audio decoding, transcription engines,
  OCR, output writing). Testable with `swift test` without the app.
- `Tools/` — command-line tools for development, such as the engine benchmark. Never shipped.

Logic goes in `VerbaKit`, not in the app target: what lives in the app can only be tested through the UI.

## Build and verify

- **Full Xcode is required**, selected with `xcode-select`. With only the Command Line Tools, `swift build`
  fails with "Unknown error parsing property list", `swift test` cannot build Swift Testing, and
  `mlx-swift` cannot compile its Metal shaders.
- Package: `swift build` and `swift test` in `Packages/VerbaKit`. App: `xcodebuild -project App/Verba.xcodeproj -scheme Verba build`.
- Formatting: `swift format` (the toolchain's swift-format) with [`.swift-format`](.swift-format). A hook
  formats every Swift file you edit; CI runs `swift format lint --strict` from M0, when the Swift job lands.
- The Stop hook (`.claude/hooks/final-checks.sh`) checks the files you edited with Edit/Write in the turn
  (not files created through Bash): Swift lint, build and tests of their packages, the app build, workflow
  and shell lint. It does not replace looking at the result: a UI change is verified by
  running the app and taking a screenshot of every state you changed.

## Models

- Every model is downloaded on first use, from a **pinned revision** (a commit hash, never `main`) and
  checked against a **SHA-256** recorded in the code before it is loaded. An unpinned or unchecked
  download is a supply-chain hole: whoever controls the upstream repository controls what runs here.
- A model's license goes in `THIRD_PARTY_NOTICES.md` in the same PR that adds it (Parakeet weights are
  CC-BY-4.0: attribution is mandatory).

## Dependencies

- Each third-party package needs a reason a few lines of our own code would not cover. License must be
  MIT, BSD, Apache-2.0 or compatible; no GPL/LGPL code in the app.
- Pin exact versions in `Package.resolved` and commit it.

## Language and code

- **Everything in the repository is in English**: code, comments, docs, commits, PRs, issues. The UI is
  localized (English and Italian) through String Catalogs.
- Swift 6 language mode with strict concurrency. No `@unchecked Sendable` or `nonisolated(unsafe)` without
  a comment that says why it is safe.
- Code comments: [`.claude/rules/code-comments.md`](.claude/rules/code-comments.md).
- **No optimization without measurement**: no change made for speed without a number before and after on
  real input. Engine and model choices follow the same rule: they are decided by a benchmark on real
  voice notes and documents (see `ROADMAP.md`), not by a leaderboard.

## Tests

A test is code to maintain and gate time on every future PR.

- **A test is born from a nameable failure**: a `.txt` that overwrites the user's file, a decoder that
  silently drops the end of a voice note, a model loaded without its checksum. If you cannot say what
  would break unnoticed without it, do not write it. A bug fix carries a test only if it reproduces the
  bug: red before the fix, green after.
- **Not tested**: wrappers without decisions, what the compiler and the frameworks already guarantee,
  views without state or rules of their own.
- **The lowest level that sees the defect**, in `VerbaKit` with Swift Testing. Test fixtures (audio,
  images) are small, synthetic or public-domain, and committed: **never a real person's voice note or
  document**, not even an anonymized one.

## Workflow

- Every change goes through a PR to `main` (squash merge; the ruleset blocks direct pushes). Work on a
  branch in its own worktree, created from a just-fetched `origin/main`.
- **Conventional Commits in English, imperative mood**: `feat(transcription): add Ogg Opus decoding`.
  Scope when unambiguous. The PR title is the subject of the branch's main commit, prefix included
  (checked by the `PR - Title` workflow): the squash uses it as the commit message on `main`.
- PR description: [`.github/pull_request_template.md`](.github/pull_request_template.md), `Closes #<issue>`
  when there is one. Write it for whoever lands on it from `git blame` in a year.
- **Before opening a PR: one code review and one security review of the diff, one pass each**, directed
  by [`REVIEW.md`](REVIEW.md) (review tools do not read it by themselves: hand it over). Skip them only
  when the diff cannot change what the system does (docs, comments, agent configuration) and say so in
  the PR. CI, permissions, entitlements, signing and model downloads always get both. Open the PR only
  when every finding is fixed, dropped with the `REVIEW.md` reason, or tracked in an issue.
- Stop and ask before anything irreversible or outward-facing: deleting data, force-pushing, publishing a
  release, changing repository settings or secrets.

## Agent configuration

Path-scoped rules in [`.claude/rules/`](.claude/rules/), hooks in [`.claude/settings.json`](.claude/settings.json).
**Hooks run only while `.claude/hooks/` matches `origin/main`**, so checking out someone else's branch never
runs their scripts: a branch that changes a hook tests it by running the script by hand. Review a fork's PR
with `gh pr diff`; checking it out and building it runs its code.
Update them yourself, in the same PR, when a turn surfaces a trap or a verified fact; say which file you
touched and why. How to write in them: [`.claude/rules/agent-configuration.md`](.claude/rules/agent-configuration.md).
