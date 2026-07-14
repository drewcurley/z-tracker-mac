# Review: feat/announcement-rendering — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] **Interactive visual/audible confirmation is deferred.** The build
      environment grants neither screen-recording nor assistive-access
      permission, so the transient toast + speech couldn't be driven and
      screenshotted here. Verification achieved: builds (debug + release),
      the app launches and runs without crashing (the `.task` poll loop +
      overlay don't break startup/render), and the engine/mapping/`poll-
      Reminders` are exhaustively unit-tested. To confirm live: run the app,
      pick a quest, expand the debug panel, toggle Ladder → within ~1 s a
      "Don't forget that you have the ladder" toast should appear (+ speak if
      the Have-key/ladder voice reminder is on).
- [ ] Reminder icons and the HDN lettered "Dungeon X complete" text variant
      are deferred refinements (the reference shows small item icons beside
      the text).

## Suggestions (consider for polish)
- The poll cadence (1 s) matches the reference; if it ever shows CPU cost,
  it could pause when the window is occluded.

## Agent Sign-offs
- [x] Analyst — scope matches T-018.3: render the T-018.2 engine's
      announcements (speech + visual) honoring the per-category options. The
      icon + HDN-label refinements are explicitly out of scope.
- [x] Architect — no security surface. The engine lives on `TrackerModel`
      (transition state survives view redraws); the view holds only the
      presentation controller. `AVSpeechSynthesizer` is standard AVFoundation.
- [x] Data Engineer — `category`/`displayText` transcribed from the
      `SendReminder` call sites (`UI.fs:1399-1615`): sword-hearts,
      dungeon-feedback (complete/found/triforce/TAG), blockers, have-key/
      ladder — with the TAG level→text ("might be"/"probably"/"are"/"need
      something") and the singular/plural forms pinned by test.
- [x] Backend — N/A (no server); `pollReminders()` is a thin model
      convenience assembling the six engine inputs.
- [x] Frontend — `ReminderController` is `@MainActor @Observable`; the
      `.task` poll loop runs on the main actor (safe to mutate the model +
      controller); toasts auto-dismiss after 6 s and cap at 5. `#Preview`/
      call sites unaffected (the overlay is additive).
- [x] UX — reminders appear as unobtrusive top-anchored toasts
      (`allowsHitTesting(false)`, so they never block the map); voice/visual
      are independently gated per the existing reminder options, and a
      "disable all" falses every category. Matches the reference's
      spoken+shown model.
- [x] Test Engineer — 5 tests: every announcement's category, the display
      strings (incl. found-count 1/9/N, triforce singular/plural, TAG levels,
      unblock dungeon-list singular/plural), and a `pollReminders` integration
      test proving a real state transition (acquire ladder) fires once through
      the owned engine. 198/198 total. UI rendering itself is not unit-tested
      (SwiftUI view) — covered by the run-without-crash smoke test.
- [x] DevOps — no CI/deploy changes; `swift build` (debug + release) +
      `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-018.md` + `tasks/T-018.3.md` updated; INDEX regenerated.

## Lens Sign-offs (user-facing rendering — Adopter/Builder)
- [x] Adopter — this is the first end-to-end *output* of the whole
      state-computation stack: the tracker now actually tells you "dungeon
      complete", "you're triforce-and-go", "go back, you have the ladder".
- [x] Builder — the pure category/text mapping lives in `TrackerCore`
      (tested), keeping the view thin; the engine-on-model placement means the
      poll loop is a three-line `.task`.
- Other lenses — N/A (internal rendering of already-decided behavior).

## Regression safety
- Contracts touched = none (in-process types + additive `TrackerModel`
  members + a new view). Reflected in docs = yes (`domain.md` § 6).
  Cross-repo consumers = none. Compatibility = additive.
- Full suite: 193/193 → 198/198, no regressions. `swift build` (debug +
  release) clean; app runs without crashing.

## Out of scope (tracked as follow-ons)
- Reminder icons; HDN lettered dungeon-complete text.
- Interactive visual/audible confirmation (needs a permissioned session).
