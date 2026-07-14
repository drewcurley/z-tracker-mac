# Review: feat/hide-tile-icons — final (T-062)

**Status:** PASS

unanimous-consensus: T-062

## Summary
A "Hide tile icons" view control in the Flags group suppresses the overworld
map's tile-selection glyphs so the terrain reads cleanly. Implemented as a new
`OverworldOverlayState.Overlay.hideMarks` case reusing the existing
hover-preview / click-lock model; `TileView` gates its digit badge, interior
icon, shop icon, `.dontCare` shading, and used-dim on `!hideMarks`.

## Sign-offs
- [x] Analyst — matches the request ("a toggle/hover under Flags to suppress the
      tile selection icons"). Scoped to a view toggle; no model/state change.
- [x] Architect — no security surface; a pure render gate on transient UI state.
- [x] Data Engineer — no schema/persistence touched; `hideMarks` is view-only,
      never written to the grid or extraData.
- [x] Backend — reuses `toggleLock`/`setHover`/`isActive`; no new logic paths.
- [x] Frontend — checkbox drives the persistent lock, row `onHover` drives the
      preview, consistent with the Info-group overlay toggles the user designed.
- [x] UX — hover previews before committing, matching the user's established
      overlay interaction; `eye.slash` glyph + tooltip communicate intent.
- [x] Test Engineer — added `hideMarksState` covering hover→preview,
      click→lock, and independence from the highlight overlays. 306/306 pass.
- [x] DevOps — no infra/deps; build clean.
- [x] Review Coordinator — task filed (T-062); INDEX regenerated.

## Regression safety
- Additive enum case + a new gated branch in `TileView`; existing overlays and
  mark rendering are unchanged when `hideMarks` is false (the default).
- Full suite 306/306 (was 305 + 1 new), build clean.
