# Review: feat/dungeon-room-details — final (T-019.7)

**Status:** PASS — dungeon room monster + floor-drop details, overlays, and the
circle/brightness gesture (D2b).

unanimous-consensus: T-019.7

## Sign-offs
- [x] Analyst — scope: the monster/floor-drop half of D2 + circle/brightness.
      Completes D2 with D2a. In scope; doors are D3.
- [x] Data — sprite index maps verified against the reference tuple order
      (`Graphics.fs:552`, `:575`) and `FloorDropDetail.Bmp()`; picker orders match
      `MonsterDetail.All()` / `FloorDropDetail.All()`; darken rule matches `:534`.
      A test asserts both orders cover every case exactly once.
- [x] UX — Shift+click details + middle circle/brightness match the reference and
      the user's chosen scheme; overlays sit where the reference draws them;
      completed/collected dimming reads as "handled". VoiceOver announces details.
- [x] Frontend — overlays are `allowsHitTesting(false)` so the mouse catcher still
      owns input; pickers reuse the D1 popover pattern; middle-click routed to the
      model's `middleClick`.
- [x] SDET — 7 new tests (picker-order completeness, darken rule across all
      monsters, middle-click circle vs brightness, both atlases load every marked
      detail). 382 total pass; clean debug + release. On-device visually verified
      via a temporary seed (removed before commit) — sprite identity, positions,
      dimming, dashed circle, and OLD MEN count all correct. Live Shift/middle
      gestures need a real-mouse confirmation (can't synthesize; NSView mouseDown
      isn't AX-actionable) — flagged, not blocking.
- [x] Architect — no security surface; local model + AppKit bridge; sprite assets
      are the reference's MIT-licensed art (NOTICE.md); `zelda_items16x16.png` was
      already bundled.
- [x] Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-019.7); INDEX updated.

## Regression safety
- Additive: two atlas loaders, one model file, one map method, and the RoomCell
  overlays/pickers. The room-type sprite path and D2a gestures are unchanged. The
  temporary visual-verification seed was confirmed removed (`grep TEMP` clean).
  Build clean debug + release; 382 tests pass.

## Follow-up
- Confirm live Shift+left / Shift+right / middle-click with a real mouse (user).
- D3: doors (the wall segments between rooms) + door gestures.
