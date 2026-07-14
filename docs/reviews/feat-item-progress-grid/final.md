# Review: feat/item-progress-grid — final (T-025.1)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Tier: routine UI render over
an existing, tested model (memory: review-rigor-tiering) — no independent
agent reviewers spawned.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] Located (yellow) / superseded (gray-X) box highlighting is **not** in
      this slice — a toggle box shows only has→green / not→dim. Tracked as
      **T-025.3**; the reference draws those states (`OverworldItemGridUI.fs:300-306`).
- [ ] The debug "Player state" panel still duplicates a few progress toggles
      (Bombs / Magical Sword / Ganon). Harmless overlap; the panel also covers
      starting-items the grid doesn't. Removing it belongs with T-025.4 chrome.

## Suggestions (consider for polish)
- Take-any hearts (bottom grid row) and the rupee/bomb-shop cells are visibly
  absent from the panel's lower area — T-025.2 fills them.

## Agent Sign-offs
- [x] Analyst — scope: render the 9 toggle item boxes (the real functional
      gap — no way to mark wood sword / candle / ring / mags / bombs / boom
      book / Ganon / Zelda) + relocate the 3 coast/armos/WS picker boxes into
      their true home. Located/superseded, hearts, and chrome are explicitly
      deferred to T-025.2/.3/.4. No scope creep.
- [x] Architect — no security surface; pure SwiftUI over existing `@Observable`
      model. Shared `RightClickCatcher` extracted (was private-duplicated) —
      one definition now, used by both grids.
- [x] Data Engineer — no schema/model change. Toggles bind to the existing
      `PlayerProgressAndTakeAnyHearts` flags via key paths; a test asserts each
      key path hits the intended flag and that all nine flags are covered once.
- [x] Backend — N/A (no server).
- [x] Frontend — grid layout is a pure, testable `ItemProgressGrid.layout`
      matching `OW_ITEM_GRID_LOCATIONS`; the view is a thin render of it. Coast
      boxes reuse `BoxView` (picker intact). Magical-sword box swaps to the
      bomb-upgrade sprite under `isWSMSReplacedByBU`. Verified on-device:
      sprites crop cleanly, layout correct, clicking wood-sword lights the
      green border + full-opacity sprite.
- [x] UX — the top-right item panel now exists; the player can record item
      progress that already fed `PlayerComputedStateSummary`/reminders but had
      no UI. Reference sprites kept; cramped 30px canvas re-laid-out as a clean
      panel (aesthetic license). Right-click clears a toggle (app convention).
- [x] Test Engineer — 7 new tests: grid shape, cell→content mapping at all 15
      positions (vs. the reference cell constants), out-of-range nil, toggle
      completeness (9 unique, all flags), key-path wiring, toggle→summary
      integration (mags⇒swordLevel 3, candle⇒candleLevel≥1, ring⇒ringLevel≥1),
      coast-box identity. 217→224, all pass.
- [x] DevOps — no CI/deploy/asset changes (reuses `icons7x7.png`). `swift
      build` + `swift build -c release` + `swift test` all clean; app runs and
      renders.
- [x] Review Coordinator — `tasks/T-025.md` (umbrella) + `tasks/T-025.1.md`
      filed; INDEX updated. No `docs/*` domain change (this renders existing
      model behavior; nothing about *what* the tracker computes changed).

## Lens Sign-offs
- Local UI render slice, not a major/strategic decision — full 7-lens review
  not triggered. Adopter note: closes the single biggest remaining
  main-tracker interaction gap (item progress had no on-screen control).

## Regression safety
- Contracts touched = none. `RightClickCatcher`/`onRightClick` moved to a
  shared file and `BoxView`/`BoxItemPicker` made internal — same behavior,
  wider visibility. The 3 coast boxes moved from the dungeon tracker's
  "Standalone" row into the item grid (no logic change; same `Box` instances).
- Full suite 217→224, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- **T-025.2** take-any hearts row · **T-025.3** located/superseded highlighting
  · **T-025.4** checkboxes/buttons/panels chrome.
