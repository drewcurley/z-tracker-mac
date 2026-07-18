# Review: feat/voice-control — final (T-137)

**Status:** PASS WITH ITEMS — working on-device voice control (structured grammar);
follow-ups tracked in T-138.

unanimous-consensus: T-137

## Scope
v1 voice: on-device speech → the same overworld/tab/cursor actions the hotkey cursor
drives. Region-aware coordinates, cursor-driven actions, and the vocabulary expansion
are explicitly deferred to T-138.

## Sign-offs
- [x] Analyst — v1 scope is the overworld-mark / take-any / tab / direction command set;
      the deferrals are captured in T-137 "Known gaps" and T-138.
- [x] Architect — voice is a thin front-end onto existing region-apply code; the audio
      engine/tap are set up once, the request swapped under a lock (no audio-thread race),
      stale callbacks ignored via a generation counter, callbacks nonisolated then hopped
      to the main actor. `.app` signed with a stable identity for TCC persistence.
- [x] Data — no schema change; take-any routes through the model's existing linkage.
- [x] Backend — grammar maps phrases to `VoiceCommand`; controller executes on the
      main actor via the shared apply/model calls.
- [x] Frontend / UX — mic button in FLAGS (green while live, echoes the last command);
      acts ~0.7 s after you stop; optional unbound hotkey.
- [x] SDET — `VoiceGrammar` is pure and unit-tested (coords/marks/take-any/two-digit
      columns/homophones): **556 tests pass**. The AVFoundation/Speech pipeline is
      AppKit-coupled and was extensively user-QA'd live (multiple command sequences).
- [x] DevOps — `build-app.sh` signs with `ZTracker Dev` (falls back to ad-hoc); `.app`
      git-ignored. No CI dependency (CI intentionally unused for this repo).
- [x] Review Coordinator — task filed (T-137); INDEX updated; follow-ups in T-138.

## Regression safety
- Voice is additive and inert until the mic is toggled on; no existing path changed
  except the shared `OverworldMark.apply` (already covered by T-135), which voice reuses.

## Items to address (T-138)
- Region-aware, cursor-driven grammar (coord moves cursor; action applies at cursor;
  dungeon context); vocabulary expansion; NATO letters; move dedup (`maxUses`) into the
  model so voice can't place duplicate dungeons; remove `/tmp` diagnostics before final.
