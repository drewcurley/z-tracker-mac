# Review: fix/spot-summary-breakout-scale-icons — final (T-216)

**Status:** PASS — the Spot Summary breakout now scales to fill its window, and its icons use the
current game-sprite art (no orange shop plate) instead of the old atlas glyphs. User QA'd and
approved. Ships in **v1.2.0** with Commentary (T-215).

unanimous-consensus: T-216

## What shipped
- Scale-on-resize: `SpotSummaryWindowView` measures the window (GeometryReader), computes a
  fill-scale (window width ÷ `SpotSummaryView.naturalWidth`, clamped 0.8×–3×), and applies the
  existing `scaledFootprint` modifier; a both-axis ScrollView catches overflow.
- Current icons: `OverworldMarkIcon` prefers `GameSprite` art (shops with no orange plate per T-212,
  real sword sprites per T-213, interior sprites, 1/2/3 five-rupee secret clusters); atlas glyphs
  remain only as a fallback. `shopBg` removed.

## Sign-offs
- [x] Analyst — scope limited to the two reported issues (scale + icon drift); no behavior change.
- [x] Architect — reuses the app's existing `scaledFootprint` zoom helper rather than a new
      mechanism; scale derived from a measured width with no content→measurement feedback (the
      GeometryReader measures the window, not the scaled content).
- [x] Data — n/a (view/derivation only).
- [x] Backend — n/a; the summary computation is unchanged.
- [x] Frontend/UX — the breakout fills a resized window (both larger and smaller) instead of
      stranding a 340-wide view; icons now match the map exactly (same sprite source), fixing the
      post-sprite-work drift. Inline popover unchanged in size, correct icons.
- [x] SDET — no logic change; **758 tests pass** (unchanged from T-215). Rendering/layout verified in-app.
- [x] DevOps — clean build/test; ships in the same notarized v1.2.0 dual-arch release.
- [x] Review Coordinator — T-216 filed; INDEX updated; rides VERSION 1.2.0 (bumped in T-215).

## Items to address (follow-ups)
- None.
