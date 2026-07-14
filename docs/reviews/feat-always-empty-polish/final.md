# Review: feat/always-empty-polish — final (T-027)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Tier: routine UI polish
(memory: review-rigor-tiering).

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The coast-item ladder box drawn on the map at `(15,5)` (`WPFUI.fs:491+`)
      is still deferred; it already lives in the item grid (T-025.1).

## Suggestions (consider for polish)
- none.

## Agent Sign-offs
- [x] Analyst — scope: two user-feedback items on T-026 — remove the X (visual
      noise) and restore the fairy-spot icons (deferred in T-026). No other
      behavior touched.
- [x] Architect — no security surface. New vendored asset `icons8x16.png`
      (206 B, MIT — NOTICE updated); no alpha channel, so it loads via the
      existing black-key `AtlasLoader` path (unlike the hearts' white-key).
- [x] Data Engineer — no data change. Fairy spots are three literal
      coordinates + a second-quest condition, ported verbatim from
      `WPFUI.fs:488-490`; a test cross-checks each is `alwaysEmpty` for its
      quest so the fairy never draws on a playable tile.
- [x] Backend — N/A.
- [x] Frontend — always-empty rendering now: darken (0.62, matching
      `.dontCare`) + optional fairy; the X overlay is gone.
      `OverworldFairySpots.isFairySpot` is pure/testable; `FairyIconAtlas`
      loads the sprite once. Non-interactivity + GYR exclusion from T-026 are
      unchanged.
- [x] UX — addresses the feedback directly: less noise (a darkened tile
      already reads as "nothing here") and the informative fairy icons are
      back. Fairy sprite kept from the reference.
- [x] Test Engineer — 229→234: fairy-spot predicate (all-quest spots,
      second-quest-only spot, non-spots), spots-are-always-empty cross-check,
      and sprite load (8×16). On-device: X gone, fairies at (3,4)/(9,3).
- [x] DevOps — one new committed asset (206 B). `swift build` (debug+release)
      + `swift test` clean; app runs and renders.
- [x] Review Coordinator — `tasks/T-027.md` filed; INDEX updated; NOTICE
      updated. No `docs/*` domain change (renders existing model behavior).

## Lens Sign-offs
- Local UI polish from direct user feedback — full 7-lens review not triggered.

## Regression safety
- Contracts touched = none. Additive: a defaulted `TileView` param + a pure
  predicate + a one-sprite atlas; the always-empty darken value changed
  0.55→0.62 (cosmetic, now matches `.dontCare`).
- Full suite 229→234, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- The coast-item ladder box on the overworld map at (15,5).
