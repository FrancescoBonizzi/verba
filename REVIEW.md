# Review instructions

How to direct and triage a code review or a security review on this repository. Review tools usually run
in their own context and do not read this file: give it to the reviewer, and in any case the agent that
receives the findings applies these rules before acting on them.

The reviewer checks every comment in the diff that states behavior against the code it describes. A false
one is Important.

## Keep a finding only when

- It names the code that causes it and the input or state that makes it go wrong.
- Every claim about behavior has a `file:line` citation, or the documented contract of the Apple framework
  or library involved. A name, a comment or a test title is not evidence.
- A performance or concurrency problem names the real situation that triggers it: a two-hour recording, a
  200-page PDF, two files dropped at once, the app quit during a model download. If it needs code that
  does not exist yet, drop it.

## Severity

- **Important**:
  - user data leaves the Mac, or a network call appears that is not a pinned model download;
  - a model or any downloaded code is loaded without its pinned revision and SHA-256 check;
  - an entitlement, a sandbox exception or a workflow permission is widened without a stated need;
  - a secret reaches code, logs or CI output; outside input reaches a shell command or a path unvalidated;
  - a user's file is overwritten, deleted or truncated;
  - the app crashes or hangs, or silently drops part of the output (the end of a recording, a PDF page);
  - a release or the signing breaks;
  - the branch does not do what its issue or `ROADMAP.md` item says "done" means;
  - a comment states behavior the code does not have.

  A violation of `CLAUDE.md` or `.claude/rules/` is Important when it has one of these effects, Nit
  otherwise.
- **Nit**: worth fixing, not blocking. At most five; count the rest in the summary.
- **Pre-existing**: a bug in code the diff touches or starts depending on. Keep it.

## Drop

- What CI already enforces: formatting, build, tests, workflow lint, secret scanning, CodeQL.
- Style, naming that is not misleading, optional refactors, comments to add to readable code.
- Logging suggestions, unless a failure would go unnoticed.
- Safe-by-default framework APIs.

## Report

Open with the count per severity, and with "No blocking issues" when there is no Important finding. If
nothing survives, say so and name any test gap left.
