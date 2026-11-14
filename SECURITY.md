# Security policy

## Reporting a vulnerability

Report privately through [GitHub's private vulnerability reporting](https://github.com/FrancescoBonizzi/verba/security/advisories/new),
never in a public issue. You will get an answer within a week. Verba is maintained by one person in their
spare time: there is no bounty.

## What counts

Verba's promise is that **nothing you give it leaves your Mac**. The most serious reports are the ones that
break it:

- any network traffic other than downloading a model from its pinned source;
- a model or any downloaded file loaded without its pinned revision and SHA-256 check;
- a crafted audio file, image or PDF that makes Verba run code, read or write outside the files you gave
  it, or overwrite your files;
- a weakness in how releases are built and signed.

## Supported versions

Only the latest release.

## Verifying a download

Releases are signed with Verba's own self-signed certificate, not with an Apple Developer ID, so macOS
asks you to confirm the first launch (System Settings → Privacy & Security → Open Anyway). Each release
lists the SHA-256 of its archive; compare it before opening. How to check the signing certificate is
described in the release notes.
