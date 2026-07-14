# Review: feat/take-any-hearts — final (T-025.2)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Tier: routine UI render over
an existing, tested model (memory: review-rigor-tiering).

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] Right-click cycles backward (an added affordance); the reference also
      binds the mouse wheel (`MouseWheel`, delta<0 = forward). Scroll-to-cycle
      isn't wired — minor, deferrable.

## Suggestions (consider for polish)
- The X for the potion/candle state is an SF Symbol `xmark`, matching the
  dungeon boxes' skip mark, rather than the reference's exact decoration
  bitmap. Consistent within the app; fine.

## Agent Sign-offs
- [x] Analyst — scope: the 4 take-any heart-cave slots (the item grid's bottom
      row), tri-state cycle + sprites. No creep into located/superseded (.3) or
      chrome (.4).
- [x] Architect — no security surface. New vendored asset `icons10x10.png`
      (604 bytes) with MIT attribution added to NOTICE. The sheet carries an
      alpha channel, so the `maskingColorComponents` key the other atlases use
      no-ops on it — the first cut rendered white backgrounds (user-reported).
      Fixed with pixel-level pure-white→transparent keying (`whiteKeyed`,
      mirroring `Graphics.fs:611`), guarded by a corner-pixel-alpha test.
      Re-verified on-device: clean transparent hearts.
- [x] Data Engineer — no model change; binds the existing
      `takeAnyHearts[i]` tri-state. Cycle math is a pure function with wrap
      tests both directions.
- [x] Backend — N/A.
- [x] Frontend — grid extended to a 4th layout row; `TakeAnyHeartBox` swaps
      full/empty sprite by state + X overlay for potion. Element mutation
      through the `@Observable` array subscript drives redraw. Verified.
- [x] UX — completes the item panel's visible bottom row; the previously
      empty lower area is now the 4 heart caves. Left=forward / right=back
      matches the app's click conventions and the reference's cycle direction.
- [x] Test Engineer — 228/228 (224→228): row-3 layout mapping incl. the empty
      4,3 cell, `cycledHeart` wrap in both directions, a
      heart→`PlayerComputedStateSummary` integration (taken heart +1 max heart,
      potion +0), and the white-key transparency regression (corner pixels
      alpha 0). On-device: all three states render (empty → red full → X).
- [x] DevOps — one new committed asset (604 B). `swift build` (debug+release)
      + `swift test` clean; app runs and renders on-device.
- [x] Review Coordinator — `tasks/T-025.2.md` filed; INDEX updated; NOTICE
      updated. No `docs/*` domain change (renders existing model state).

## Lens Sign-offs
- Local UI render slice — full 7-lens review not triggered.

## Regression safety
- Contracts touched = none. Additive: new atlas, new cell cases
  (`takeAnyHeart`/`empty`), a 4th grid row. Existing 3 rows unchanged.
- Full suite 224→226, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- **T-025.3** located/superseded highlighting · **T-025.4** chrome · optional
  scroll-wheel cycle for the hearts.
