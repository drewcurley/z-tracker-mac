# Review: feat/overworld-icons-leftclick — final (T-191)

**Status:** PASS — overworld icon refresh + left-click reopen + picker reorder.
QA'd on device across the map, the graphical chooser, and the Spot Summary; user signed off
("those all look good").

unanimous-consensus: T-191

## What shipped
- Unknown secret → pale-white **ghost rupee** (desaturated/brightened `Rupy` sprite);
  hint → gray **"?" tile** (digit-tile style). New `OverworldTileIconSource` cases
  `.ghostRupee` / `.hintTile`, rendered in map / chooser / Spot Summary (single source via
  `TileView`).
- **Left-click reopens the chooser** on unknown-secret and shop tiles (shared
  `openMarkChooser`), matching the existing Don't-Care reopen.
- Graphical picker: money-game ↔ door-repair swapped; take-any reordered potion → candle →
  heart (in-game order).

## Sign-offs
- [x] Analyst — scoped to the four user asks; no reference-parity mechanic changed (these
      are deliberate cosmetic/UX deviations, like the door-repair "fire" gag).
- [x] Architect — icon source is pure model data (TrackerCore); rendering is additive.
- [x] Data — `iconSource` mapping is total; round-trip/raw-index unaffected (unchanged).
- [x] Backend — left-click dispatch reuses the existing chooser path; no new state.
- [x] Frontend / UX — glyphs read at map scale and in the chooser; picker order matches
      in-game; verified on device.
- [x] SDET — icon-source + chooser-layout tests updated; **724 pass**.
- [x] DevOps — clean build/test; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-191); INDEX updated.

## Items to address (follow-ups)
- Ghost-rupee tint + hint gray are single constants — trivial to retune if needed.
