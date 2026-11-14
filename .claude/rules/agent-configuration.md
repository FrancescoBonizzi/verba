---
paths:
  - "**/CLAUDE.md"
  - "REVIEW.md"
  - ".claude/**"
---

# Writing agent configuration

How to write in `CLAUDE.md`, `.claude/rules/`, skills and hooks. *When* to update them (yourself, in the
same PR) is in the root `CLAUDE.md`.

- **Choosing the lever**: a deterministic check → a hook; a convention tied to some paths → a rule;
  overview, commands, verification and soft guidance → a `CLAUDE.md`; a long procedure needed only
  sometimes → a skill. No hook for what a rule can state in prose.
- **A path-scoped rule loads only when a matching file is read**: what must fire earlier (deciding
  *whether* to do something) stays in an always-loaded file, even as a single line.
- **These files hold project rules, not personal preferences.** The test: if a contributor does not
  follow the line, does someone else pay (the code, CI, the reviewer, the users)? Then it belongs here.
  If only that contributor pays, it goes in their own `~/.claude/CLAUDE.md`.
- **Every line in an always-loaded file is paid in every session.** Check it is not already said and that
  it does not belong closer to the code it governs. Prefer tightening or replacing a line to appending
  one; remove what has gone stale.
- A skill teaches how to find something out at runtime, not lists of names that go stale at the first
  rename. Its `description` is paid in every session too: say when to use it, not what it contains.
