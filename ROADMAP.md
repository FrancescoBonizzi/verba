# Roadmap

What Verba will do, in which order, and why. Decisions are recorded with the reason and with what would
reopen them: when one changes, this file changes in the same PR.

## Principles

- **Local only.** Audio, images and documents never leave the Mac. The only network traffic is a model
  download from a pinned source, checked against its SHA-256.
- **Native and quiet.** SwiftUI/AppKit, Apple-style UI, a good default instead of a setting.
- **Measured, not assumed.** Engines and models are chosen by a benchmark on real voice notes and
  documents. Public benchmarks are read speech in clean conditions; voice notes are not.

## Decisions

| Topic | Decision | Why | Reopen if |
|---|---|---|---|
| Platform | macOS 27+, Apple Silicon only | MLX runs only on Apple Silicon; one code path for the native speech and audio APIs | someone who matters to the project is stuck on an older macOS |
| Shape | A regular app (one window, drop on the Dock icon) plus a Finder Quick Action "Transcribe with Verba" | Every job starts from a file; nothing needs to run in the background | dictation comes back (it needs a menu bar presence) |
| Project | Xcode project with synchronized folders for the app shell; all logic in the local Swift package `VerbaKit` | Apple's standard layout; logic testable with `swift test`; the opaque `.pbxproj` changes only when targets or settings do | — |
| Audio decoding | AVFoundation, no ffmpeg | macOS opens Ogg/Opus natively (verified on macOS 27.2 with a generated file); no LGPL/GPL code | real WhatsApp or Telegram voice notes fail to decode |
| Transcription engine | Chosen by the M1 benchmark | No public data on noisy, spontaneous Italian voice notes | — |
| OCR | Apple Vision first; a local VLM only where it beats Vision on real documents | Vision is free, instant and installed; a VLM is gigabytes to download | — |
| Distribution | GitHub Releases only, no App Store | — | — |
| Signing | A stable self-signed certificate, no Apple Developer ID | No yearly fee for a free project. Cost: macOS asks to confirm the first launch once (Privacy & Security → Open Anyway) | the self-signed identity does not keep permissions across updates (verified in M0): then compare paying for a Developer ID with other packaging. An Electron app is not a way out: it hits the same Gatekeeper and permission rules, and loses the native APIs Verba is built on |
| License | MIT | Same as the main dependencies; no restriction on reuse | — |
| Language | Everything in English; UI in English and Italian | Open to any contributor | — |

## Milestones

Each milestone ends with its exit criteria met, not with its list done. An item is checked in the PR
that completes it.

### M0 — Foundations

- [x] Install full Xcode on the development Mac.
- [x] Create `App/Verba.xcodeproj` (app target with App Sandbox, Quick Action extension) and
  `Packages/VerbaKit`, as described in `CLAUDE.md`.
- [x] CI: build and test on a macOS runner, `swift format lint --strict`; add the `swift` ecosystem to
  Dependabot; make the new checks required in the `main` ruleset.
- [ ] Add Swift to the CodeQL matrix: blocked until CodeQL supports Swift 6.4 (issue #3).
- [ ] **Verify the signing plan before building on it**: sign two different builds with the same self-signed
  certificate and check that a granted permission (Speech Recognition) survives the update, and that the
  Finder Quick Action loads.
- [x] **Verify the sandbox can write the `.txt` next to the dropped file** (sandbox "related items"), or
  decide where the output goes instead.
- [x] **Verify the GitHub macOS runners have an Xcode with the macOS 27 SDK**; if not, decide between a
  self-hosted runner and lowering the deployment target.

Exit: an empty app builds and launches from CI artifacts on a clean Mac, and the three checks above have a
written answer here.

**Status: not exited.** Left for the maintainer: launch the CI artifact on a Mac other than the development
one, check the Quick Action in Finder, and the signing check above (in M2).

What the checks found:

- **Signing.** A self-signed code-signing certificate gives every build the same designated requirement
  (`identifier "io.github.francescobonizzi.verba" and certificate leaf = H"…"`): verified on two different
  builds. The certificate and its key must be kept: a new one changes the hash. A Release build with the
  hardened runtime on launches when signed ad hoc (verified); with the self-signed certificate it is
  deduced, not yet run. A Debug build with the runtime on crashes at launch, so Debug keeps it off. The Quick Action extension registers with
  the system (`pluginkit -m -i io.github.francescobonizzi.verba.QuickAction`) without the app being in
  `/Applications`. **Still to verify by hand**, because they need someone at the screen: that the action
  shows in Finder's Quick Actions, and that a granted Speech Recognition permission survives an update.
  The second needs an app that asks for the permission, so it moves to M2: create the self-signed
  certificate, sign two different M2 builds with it, grant the permission on the first, install the second.
- **Sandbox.** A sandboxed app that receives `note.ogg` can write `note.txt` next to it, through "related
  items": the `.txt` type declared with `NSIsRelatedItemType`, and an `NSFilePresenter` whose primary item
  is the audio file (verified with `open -a`). It works only for the same base name, so the numbered name
  that avoids overwriting (`note 2.txt`) is not covered; Apple's DTS also advised in 2026 against relying
  on related items. What happens when `note.txt` already exists is decided in M2's output item;
  `TextOutput`'s numbered fallback works outside the sandbox only and goes away there.
- **Runners.** Only GitHub's `xcode-27` image, a public preview, has the macOS 27 SDK; CI uses it. If it
  turns out unstable, the alternative is a self-hosted runner on a Mac. **WARNING:** a self-hosted runner
  must never serve `pull_request` workflows from forks: a fork's PR runs its own code on that Mac.

### M1 — Transcription benchmark

A command-line tool in `Tools/` that transcribes a corpus with every candidate engine behind one
`TranscriptionEngine` protocol, and reports the numbers.

Candidates:

| Engine | Runs via | Weights | Notes |
|---|---|---|---|
| Apple `SpeechTranscriber` | Speech framework | System-managed, already installed for Italian | Nothing to download |
| Apple `DictationTranscriber` | Speech framework | System-managed | Close to system dictation; decides whether dictation comes back |
| Whisper large-v3-turbo | WhisperKit (MIT) | ~1.6 GB, MIT | Built-in VAD; known to hallucinate on silence and to loop |
| Parakeet TDT 0.6B v3 and Ultra | FluidAudio (Apache-2.0) | ~0.6 GB, CC-BY-4.0 (attribution) | ~25× faster than Whisper turbo; native punctuation |
| Voxtral Mini (optional) | mlx-audio-swift | ~2.3 GB at 4-bit | Best public Italian score; include only if the Swift port runs |

whisper.cpp is not a separate candidate: it runs the same Whisper weights as WhisperKit, through a C bridge
instead of native Swift and Core ML, so measuring Whisper once is enough.

What public data says (FLEURS Italian, read speech, word error rate; lower is better):

| Engine | WER | Source |
|---|---|---|
| Whisper large-v3-turbo | 2.6–2.8% | [Whisper Notes](https://whispernotes.app/blog/apple-speech-vs-whisper), [Handy](https://models.handy.computer/languages/it) |
| Parakeet Ultra | 2.0–2.6% | Moondream, Handy, Whisper Notes |
| Parakeet v3 | 3.0% | [NVIDIA model card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) |
| Apple SpeechTranscriber | 4.4% | Whisper Notes |
| Apple DictationTranscriber | 6.9% | Whisper Notes |

On FLEURS, differences under about one point are ties. No public number exists for noisy, spontaneous
Italian: that is what M1 measures.

Protocol:

- **Corpus**: about 50 real voice notes (at least 30 minutes in total) plus 20 clips of silence or
  background noise. Reference transcripts are made by correcting a first draft by hand. **The corpus
  never enters the repository**: it lives outside it, and `.gitignore` blocks `Tools/**/corpus/` as a
  safety net.
- **Text normalization**, identical for every engine: Unicode NFC, lowercase, punctuation removed with the
  apostrophe turned into a space (`l'ora` → `l ora`), accents kept (`e` and `è` are different words),
  numbers in one form, fillers (`ehm`) removed on both sides.
- **Metrics**: corpus-level WER with a bootstrap confidence interval, CER as a cross-check; hallucination
  rate (any text on silence clips, repeated n-grams ≥ 3); real-time factor with the model warm and cold;
  peak memory.

Exit: a report with these numbers, and the chosen engine recorded in the Decisions table with its reason.
An engine joins the app only if it wins on something the others do not cover.

### M2 — Transcribe audio files

- [ ] Drop on the window or the Dock icon, or the Finder Quick Action.
- [ ] Language: Italian or English chosen explicitly, default from the system language. Auto-detection is off
  by default: on short voice notes it guesses wrong.
- [ ] If the engine is Whisper: VAD to cut silence and loop detection on the output.
- [ ] Output: text in the clipboard and a `<name>.txt` next to the file. Verba marks the `.txt` files it
  writes (an extended attribute, invisible in Finder). When `<name>.txt` exists: if Verba wrote it, it is
  replaced without asking (a new transcription is what the user wants); if not, Verba asks **before
  transcribing** whether to replace it or save elsewhere, and never overwrites a file it did not write
  without that answer. A numbered name (`<name> 2.txt`) is not an option: the sandbox does not allow it
  (see the M0 findings), so `TextOutput`'s numbered fallback is removed.
- [ ] Model download manager (if the engine needs weights): pinned revision, SHA-256 check, progress, resume,
  delete from the app.

Exit: a week of daily use on real voice notes without falling back to another tool.

### M3 — OCR with Apple Vision

- [ ] Images, screenshots and PDFs (pages rendered through PDFKit; text PDFs read directly).
- [ ] Output: plain text in the clipboard and a `.txt`, same rules as M2.

Exit: screenshots and simple documents come out right; a set of documents where Vision fails is collected
for M4.

### M4 — OCR for complex documents

- [ ] GLM-OCR through `mlx-swift-lm` (MIT code, MIT weights, officially supported, MLX weights ready).
  Markdown output with tables.
- [ ] Qwen3-VL (4B or 8B, also supported by `mlx-swift-lm`) as the general-purpose alternative, measured in
  the same benchmark: several times larger than GLM-OCR, so it earns its download only where GLM-OCR fails,
  for example on handwriting.
- [ ] Benchmark against Vision on the M3 failure set: tables, multi-column layouts, handwriting.
- [ ] The VLM is offered only for documents where it wins, and is downloaded only when first needed.

Exit: the M3 failure set comes out usable, with numbers on time and memory.

### M5 — Releases

- [ ] A release workflow: build, sign with the self-signed certificate (key in GitHub secrets, used only by
  that workflow, in a protected environment), zip, SHA-256, build provenance attestation, GitHub Release.
  The key goes into a temporary keychain with `security set-key-partition-list`, or codesign stops on a
  keychain access prompt that nobody can click.
- [ ] Install notes in the README: first launch, how to verify the archive and the certificate.
- [ ] `THIRD_PARTY_NOTICES.md` with every dependency and model license (Parakeet's CC-BY-4.0 attribution).

Exit: someone who is not the maintainer installs Verba from a release, following only the README.

## Parked

Not planned. Each one says what would bring it back.

- **Global dictation** (hotkey, record, paste into the active app). The question behind it: is macOS's
  built-in dictation good enough, given that the one on an older iPhone is not? M1 measures Apple's
  dictation engine (`DictationTranscriber`) on real voice notes; dictation comes back if it is clearly
  worse than the winner.
- **Meeting notes** (system audio through ScreenCaptureKit, microphone and others on separate tracks).
  Comes back after M2 is in daily use.
- **Summaries with a local LLM.** Out: summaries go to a frontier LLM anyway.
- **PaddleOCR-VL.** Only a young third-party Swift port exists; comes back with official `mlx-swift-lm`
  support.
- **Video files.** Out for now.

## Open questions

- Minimum macOS version that decodes Ogg/Opus natively: irrelevant while the target is macOS 27, matters
  if it is ever lowered.
- Whether Parakeet Ultra's weights and conversion are stable enough to pin (published by Moondream, not by
  NVIDIA; training method not published).
