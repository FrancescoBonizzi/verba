# Contributing to Verba

Thanks for wanting to help. Verba is small on purpose: few features, few settings, everything on the Mac.
Read [`ROADMAP.md`](ROADMAP.md) before proposing a feature, and open an issue describing the problem
before writing a large change.

## Setup

- A Mac with Apple Silicon and macOS 27 or later.
- Full Xcode (the Command Line Tools are not enough: MLX compiles Metal shaders through Xcode).

Build and test commands are in [`CLAUDE.md`](CLAUDE.md), § "Build and verify": it is written for AI
coding agents and reads just as well for humans.

## Pull requests

- One topic per PR, from a branch, to `main`. PRs are squash-merged.
- The PR title follows Conventional Commits in English, imperative mood: `fix(ocr): keep table rows in order`.
- Fill in the PR template: what changed, why this way, how you tested it.
- Never commit real recordings, documents or screenshots of real people: test fixtures are synthetic or
  public domain.
- New dependencies need a reason and a MIT/BSD/Apache-2.0-compatible license.

## AI-assisted contributions

Welcome. The repository is configured for [Claude Code](https://claude.com/claude-code) (`CLAUDE.md`,
`.claude/`), and the same rules apply to code written by agents: you are responsible for every line you
submit, and the PR says how you verified it.
