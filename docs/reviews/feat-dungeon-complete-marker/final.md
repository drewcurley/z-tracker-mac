# Review: feat/dungeon-complete-marker — final (T-035.6)

**Status:** PASS

unanimous-consensus: T-035.6

## Summary
A 100%-complete dungeon's overworld badge now dims: the digit/letter badge
switches to dark yellow `RGB(153,153,0)` (reference-faithful) and the tile also
gets the full-tile "used" dim overlay (user request, for visual consistency with
other done tiles). `dungeonComplete: (Int) -> Bool` threads per-slot
`Dungeon.isComplete` into `TileView`.

## Sign-offs
- [x] Analyst — matches the request; the extra full-tile dim (beyond the
      reference's badge-only shading) is an explicit user call for consistency.
- [x] Architect — no security surface; render-only.
- [x] Data Engineer — reads the already-tested `Dungeon.isComplete`; no state
      added. Slot→id is `slot-1`, guarded to `1...9`.
- [x] Backend — no logic changed; a view closure over existing state.
- [x] Frontend — badge background swap + `used || dungeonComplete` on the dim
      overlay, both inside the `!hideMarks` gate so T-062 still suppresses them.
- [x] UX — completed dungeons read as "done" like claimed tiles; verified
      distinct from bright incomplete neighbors on-device.
- [x] Test Engineer — `isComplete` is unit-tested; the dim is a view-only color
      swap verified on-device (no snapshot harness). 320/320 pass, build clean.
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-035.6); INDEX regenerated.

## Notes / follow-ups
- User reported the app **beachballing** during rapid automated input (auto-map
  + several dungeon edits in quick succession). Likely release-build warm-up +
  bulk re-render under synthetic clicks, but flagged for a perf pass if it
  recurs interactively.
- User request captured for the hint-decoder task (T-016.x/#5): placing a
  `.dungeon(N)` marker should set that dungeon's `levelHint` to the tile's
  region.

## Regression safety
- Additive prop + two gated render tweaks; incomplete dungeons and all non-
  dungeon tiles are unchanged. Full suite 320/320, build clean. On-device: a
  completed dungeon dims (dark badge + full-tile overlay).
