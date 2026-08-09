# Review: fix/reminder-hud-bugs — final (T-193)

**Status:** PASS — two user-reported display bugs fixed (HUD letter slot reversed; boomstick
nudge ignored the Boomstick flag). Bug-fix scope (Backend + SDET + Ops) per CLAUDE.md.

unanimous-consensus: T-193

## What shipped
- **HUD letter slot**: `ProgressHUDView.haveLetter` now reports *holding* the letter
  (placed & `!isUsed`), matching the letter tile's inverted dim (T-118) and the map-derived
  `havePotionLetter`. Extracted a pure `holdsPotionLetter(_:)` for testing.
- **Boomstick nudge**: `considerBoomstickBook` is now gated on `!isCurrentlyBook` (boomstick
  seed), so turning the Boomstick flag off clears the reminder; `hasBoomBook` still stops it.

## Sign-offs
- [x] Backend — both are pure condition fixes; no new state, no behavior beyond the reported
      cases.
- [x] SDET — added/updated tests: HUD letter held-state; boomstick nudge gated on the flag,
      the bought-book case, and the no-shop case. **725 tests pass.**
- [x] DevOps — clean build/test; `.app` rebuilt for QA.
- [x] Analyst — scoped strictly to the two reported bugs.
- [x] Architect / Data / Frontend / UX — n/a (no schema/UI-structure change); glyph + nudge
      behavior QA'd on device.
- [x] Review Coordinator — task filed (T-193); INDEX updated.

## Items to address (follow-ups)
- None.
