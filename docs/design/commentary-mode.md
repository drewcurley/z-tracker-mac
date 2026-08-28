# Commentary Mode — design spec

**Status:** approved plan (pre-build) · **Date:** 2026-08-24 · **Author:** Drew Curley (solo)

## Purpose

When two players race the same seed, a commentator runs a tracker to narrate the race. Beyond
knowing what everything *is* (spots, items, rooms), it's useful to track **which runner has
discovered / knows** each thing. **Commentary Mode** adds a per-session layer over the existing
tracker that records, per element, who knows it.

This is a **commentator-only** tool — it is never shown to stream viewers — so it's optimized
purely for the commentator's own at-a-glance reading, with no broadcast-legibility constraint.

## Model

- The existing tracker remains the single **shared truth** (what each spot/item/room is).
- On top, a **knowledge overlay**: each element carries two independent bits — `{runner1, runner2}`
  — giving four states: **neither · R1 · R2 · both**. The overlay never changes what a thing *is*.
- **Not** two separate trackers (a commentator can't maintain two); one truth + one overlay.
- Two runners per session with **editable names** (default "Runner 1" / "Runner 2") and **colors**
  (default red `#e03a3a` / blue `#2f7ff0`).

## Mode toggle

- Commentary Mode is toggled on/off. **Off** = today's tracker exactly (no overlay, no commentary
  gestures). **On** = overlay renders and the commentary gestures below are live.

## Interaction (primary: modifier-click)

Matches the app's modifier-click marking convention — no forced keyboard use mid-cast:

- **⌥-click** a tile → toggle **Runner 1**'s knowledge of it.
- **⌥-right-click** a tile → toggle **Runner 2**'s knowledge.
- Each gesture toggles that runner independently: both gestures → both; repeat a gesture → clear.

Commentary gestures only fire while Commentary Mode is on, and do not disturb the normal
left/right-click marking.

*(Deferred: a dedicated commentary hotkey context, if wanted later.)*

## Visual encoding (two options, selectable in Settings)

Both drive off the runner colors:

1. **Corner pips** — a small colored triangle in the **top-left** (R1) and **top-right** (R2)
   corners; lit when that runner knows. Both lit = both. Tucks into corners, clear of center
   content (dungeon numbers, item glyphs).
2. **Edge border** — a single runner colors the **whole frame**; **both** splits the frame down
   the middle (left half R1, right half R2, meeting at top-center and bottom-center) via a
   gradient border-image.

Validated in an interactive mockup with the user (both encodings, all four states, custom colors,
over busy tiles).

## Persistence

Saved with the game state (races run long): the per-element knowledge data, runner names, and
runner colors. The mode-on flag and encoding choice are display preferences (see below).

## Phasing

- **Phase 1 (first build): overworld tiles only** — the biggest commentary payoff and the hardest
  visual case; proves the model + gesture + encoding.
- **Later phases:** dungeon item boxes, the collectible item grid, dungeon room maps, and the
  blockers grid — each reusing the same model, encoding, and gesture.

### As shipped (v1.2.0) — five surfaces, one store

All five ship together in v1.2.0. A single string-keyed store (`CommentaryLayer.marks`) serves
every surface via a namespaced key, so one save field and one encoding cover them all:

| Surface | Key | Pip corners (R1 / R2) |
|---|---|---|
| Overworld tiles | `ow:col,row` | top-left / top-right |
| Dungeon item boxes | `box:dungeon,index` | top-left / top-right |
| Collectible item grid | `item:id` | top-left / top-right |
| Dungeon room maps | `room:dungeon,col,row` | **bottom-left / top-right** (monster owns top-left, drop owns bottom-right) |
| Blockers grid | `blk:dungeon,slot` | top-left / top-right |

**Gesture (app-wide):** ⌥-click = runner 1, ⌥-right-click = runner 2. On dungeon room maps this
required moving the room "circle"/brightness (and door "yellow") off ⌥ onto **⌘-click / ⌘-drag**,
so ⌥ is unambiguously the commentary modifier everywhere.

## Implementation sketch (Phase 1)

- **Data (TrackerCore):** a knowledge value per overworld screen — an `OptionSet`/small enum
  `{r1, r2}` keyed by `OverworldScreenCoordinate`, held on the model and included in the save
  snapshot (versioned, back-compatible — absent in old saves = empty).
- **Session identity (model, saved):** runner names + colors.
- **Prefs (`TrackerOptions`, persisted globally):** `commentaryMode: Bool`, `commentaryEncoding:
  enum { pips, border }`.
- **Rendering:** an overlay in `TileView` (pips or split border) gated on `commentaryMode`, driven
  by the screen's knowledge state + encoding + runner colors.
- **Gesture:** detect ⌥-modified left/right clicks on overworld tiles and route them to toggle the
  runner bits (instead of the normal mark path) while the mode is on.
- **Legend:** show the two runner names/colors somewhere while the mode is on (e.g. a small
  header/strip), plus a "clear all commentary" affordance.

## Open questions for later phases

- Exact home for the mode toggle + encoding picker (Flags tile vs Settings vs a Commentary menu).
- Whether the other surfaces need any per-surface tweaks to the encoding.
- Optional hotkey context.
