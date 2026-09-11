# Review: feat/armos-eligibility-deduction — final (T-223)

**Status:** PASS — Armos is restricted to its five eligible screens across every marking path,
auto-deduced once the other four are ruled out, with a named alert that fires only on deduction.
User QA'd and approved. Commits on its own; **ships in v1.2.5 with the shop changes (T-224).**

unanimous-consensus: T-223

## What shipped
- Eligibility from the existing `OverworldInstance.hasArmos` mask (verified to match the five
  screens); `ArmosLocation` nickname table; `TrackerModel.canMarkArmos`.
- Restriction wired into the graphical chooser (`armosAllowed`), the menu Armos button, the hotkey
  dispatcher, voice, and a central `applyMark` guard.
- `applyArmosDeduction()` auto-marks the fifth (adds only) and reports a *fresh* deduction; run in
  `pollReminders` + `restore`. New `ReminderAnnouncement.armosLocated(name:)` fires only on that
  deduction (manual mark is silent).

## Sign-offs
- [x] Analyst — matches the request (five screens + deduce + named alert); user-supplied screens and
      nicknames; custom-map exemption is correct (vanilla-only concept).
- [x] Architect — reuses the reference armos mask rather than hardcoding; deduction only adds (manual
      corrections survive); eligibility centralized in one model helper used by all paths.
- [x] Data — no schema change; the deduced mark is a normal overworld mark, saved/restored as usual.
- [x] Backend — every marking path (menu / chooser / hotkey / voice / applyMark) gated identically.
- [x] Frontend/UX — ineligible screens hide (menu) / dim+disable (chooser) the armos option; the
      alert speaks only on deduction, so manual marking isn't chatty (per user).
- [x] SDET — `ArmosTests` (mask↔name, canMarkArmos, deduction variants, manual-silent, fire-once).
      **778 tests pass.**
- [x] DevOps — clean build/test. VERSION → 1.2.5; **no release cut yet** — bundling with T-224.
- [x] Review Coordinator — T-223 filed; INDEX + CHANGELOG (1.2.5) updated.

## Items to address (follow-ups)
- Ships together with the shop changes (T-224) as the single v1.2.5 release.
