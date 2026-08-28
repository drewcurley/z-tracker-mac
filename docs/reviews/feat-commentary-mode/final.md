# Review: feat/commentary-mode — final (T-215)

**Status:** PASS — a commentator-only runner-knowledge overlay across five surfaces (overworld,
dungeon items, item grid, room maps, blockers), two selectable encodings, per-session runner
identities. User QA'd every surface and approved. Ships in **v1.2.0** (with T-216 spot-summary polish).

unanimous-consensus: T-215

## What shipped
- `CommentaryLayer` (TrackerCore, `@Observable`): one namespaced string-keyed store
  (`ow:` / `box:` / `item:` / `room:` / `blk:`) of a `{runner1, runner2}` `OptionSet`, plus editable
  runner names/colors, saved in the model snapshot (optional field → back-compatible).
- `TrackerOptions`: persisted `commentaryMode` + `commentaryEncoding` (pips / border).
- `CommentaryOverlay.swift`: `CommentaryTileOverlay` (non-hit-testing pips/border), the ⌥-only
  `OptionRightClickCatcher`, `.commentaryCell(…)`, `CommentaryLegendBanner`, hex↔Color bridges.
- All five surfaces wired: ⌥-click = runner 1, ⌥-right-click = runner 2, gated on the mode.
- Room maps: circle/brightness + door "yellow" moved to **⌘-click / ⌘-drag** (`RoomMouseCatcher`),
  freeing ⌥ app-wide; room pips use the free corners so they never collide with monster/drop.
- A dedicated **Commentary…** settings subscreen (toggle, encoding, runner name/color, clear-all).

## Sign-offs
- [x] Analyst — scope held to the requested overlay; commentator-only (never on-stream); five
      surfaces = the "overworld, dungeon items, collectible items, dungeon map, blockers" ask.
- [x] Architect — one pure `@Observable` store keyed by namespaced strings; no coupling to any
      surface's model; save field optional so old saves load; overlays are `allowsHitTesting(false)`
      so decoration never eats clicks; ⌥-right catcher claims *only* ⌥+right so normal right-click
      is undisturbed.
- [x] Data — no schema/query change; snapshot gains one optional Codable `State` (marks as raw ints
      + names/colors); round-trip tested.
- [x] Backend — every surface routes ⌥-gestures to `toggle(_:key:)` on the shared layer; knowledge
      reads gate on `commentaryMode` so toggling the mode off suppresses all marks.
- [x] Frontend/UX — pips vs border both legible at each cell size; room corners chosen around
      existing markers; legend banner fills the previously-cramped open band; the gesture matches
      the app's ⌥-elsewhere convention; ⌘ takes over the former ⌥ room/door actions consistently.
- [x] SDET — `CommentaryLayerTests`: toggle cycle, sparse-clear, clear-keeps-identities, key
      distinctness across all five surfaces, save/restore. **758 tests pass.**
- [x] DevOps — clean `swift build` + `swift test`; app rebuilt/relaunched for QA; ships as notarized
      dual-arch DMGs + appcasts in v1.2.0.
- [x] Review Coordinator — T-215 filed; design doc updated with the as-shipped surface table; INDEX
      updated; VERSION → 1.2.0.

## Items to address (follow-ups)
- Spot Summary breakout polish (scale-on-resize + current sprite icons) — **T-216**, separate branch,
  same v1.2.0 release.
