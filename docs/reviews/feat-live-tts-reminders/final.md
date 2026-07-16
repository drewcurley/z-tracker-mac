# Review: feat/live-tts-reminders — final (T-069, T-068, T-086)

**Status:** PASS — reminders migrated to live TTS; overlap + pronunciation fixed.

unanimous-consensus: T-069

## What changed
- **Live TTS (T-069).** One shared `SpeechEngine.AVSpeechSynthesizer` speaks all
  reminders with **Zoe (Premium)** (fallback: user's chosen voice, then system
  default). Primed at launch (`ContentView.task`) by speaking a silent space —
  loads the speech service + voice model + coreaudiod before the first reminder.
- **No overlap (T-068).** The shared synth queues utterances, so a batch speaks
  sequentially. The clip path (unserialized `AVAudioPlayer`) that caused the
  overlap is gone.
- **Pronunciation (T-086).** `SpeechText.spoken` rewrites "triforce" → "try force"
  for the voice engine; the visible toast keeps the real spelling.
- **Removed:** `ReminderAudioPlayer`, 40 `Resources/audio/*.m4a`,
  `scripts/generate-reminder-audio.{sh,swift}`, `ReminderAnnouncement.audioKey`,
  the `.copy("Resources/audio")` resource, and the clip/TTS branch.

## Sign-offs
- [x] Analyst — completes the two logged backlog tasks (T-068/T-069) + the user's
      pronunciation ask (T-086). In scope.
- [x] Architect — one shared synth; no new concurrency primitives. Bundle shrinks
      by 40 clips.
- [x] Data — `SpeechText` is a pure transform; unit-tested.
- [x] Backend — `ReminderController.handle` simplified to a single speak path.
- [x] Frontend — `SpeechEngine` resolves voice + serializes; warm-up at launch.
- [x] UX — natural Zoe voice, correct "triforce" pronunciation, no overlap.
- [x] SDET — 439 tests pass (SpeechText added; audioKey/clip tests removed).
      Clean boot with no audio resources verified; a triforce reminder fires
      without crashing on-device.
- [x] DevOps — pipeline + generation script removed; no infra dependency.
- [x] Review Coordinator — T-086 filed; T-068/T-069 marked completed; INDEX updated.

## Verification note
- Audio **quality/latency** (natural voice, no overlap, instant first reminder on
  a cold launch) can't be measured headlessly — ships build-verified + clean-boot
  + no-crash-on-fire, pending the user's real-run confirmation. The launch warm-up
  is the first-use-latency mitigation; if a cold first reminder still lags, revisit
  warming earlier / with the resolved voice.

## Regression safety
- Visual reminders unchanged (real spelling, same toasts). Per-category
  voice/visual toggles and volume still honored. Full suite green.
