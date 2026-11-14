---
paths:
  - "**/*.swift"
  - "**/*.sh"
  - ".github/**/*.yml"
---

# Code comments

Rules for **internal** comments (`//`, `#`, `/* */`). Documentation comments (`///`) on public API are
not covered: they are optional.

## What to write

- **The why, not the what.** If the comment restates the line below, delete it. If it is needed to
  understand *what* the code does, rename the code instead: a comment does not redeem a bad name.
- **One sentence per idea.** An inline comment is one line; a block over five lines usually holds several
  ideas, or is a README in disguise. Shortening never drops the data: the measurement, the number, the
  error name, the condition that breaks stay.
- **Write for yourself in six months**: the external constraint, the measurement behind a choice, the
  assumption the code rests on, the edge case, the rule that the code alone does not reveal.
- **Explain the non-idiomatic**: a forced cast, a workaround, an order that looks arbitrary. Without the
  why, the next person "simplifies" it and breaks something.
- **Fixing a bug, leave the failure mode**, not the story of the fix: what broke and under which
  conditions.
- **Link instead of paraphrase**: copied code links its source; a constraint that lives elsewhere (an
  Apple doc, an issue) is linked, not copied.

## Warning tags, not emoji

Closed vocabulary, uppercase, colon, at the start of the comment:

| Tag        | When                                                   |
| ---------- | ------------------------------------------------------ |
| `TODO:`    | incomplete on purpose, with why it is out of scope     |
| `FIXME:`   | known defect here, not fixed yet                       |
| `HACK:`    | deliberately non-idiomatic, with why                   |
| `WARNING:` | changing this breaks something somewhere else          |
| `NOTE:`    | non-obvious assumption or constraint                   |

No emoji in comments: Xcode's jump bar and IDE task lists pick up these tags, emoji are neither
highlighted nor reliably searchable.

## What not to comment

- **Commented-out code**: delete it, git remembers. A failing test is disabled through the framework
  (`.disabled("reason")` in Swift Testing), not commented out.
- **"It used to be / now it is" narration**: git remembers. Only today's constraint matters.
- **ASCII banners** (`// =====`). `// MARK: -` is fine: Xcode uses it for navigation.
