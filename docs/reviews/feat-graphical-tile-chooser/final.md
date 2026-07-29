# Review: feat/graphical-tile-chooser — final (T-185)

**Status:** PASS — an optional graphical overworld tile chooser plus a batch of
user-requested overworld/dungeon/reminder refinements. QA-approved on device.

unanimous-consensus: T-185

## What shipped
- **Graphical tile chooser (option, default off):** `graphicalOverworldChooser` in
  `TrackerOptions` (toggle in `SettingsPanelView`, which the startup screen embeds). A
  5×8 icon grid (shops / secrets+door-repair+MMG+hint+potion / letter+armos+take-any
  ×3+don't-care+unmarked+start / levels 1–8 / L9+any-road 1–4+swords 1–3), reusing the
  map's own `TileView` glyphs. Exhausted marks dim + disable. Scroll-up on a tile opens
  the overworld enemy picker. No "?" any-road in the grid.
- **Left-click on a Don't-Care tile opens the chooser** — graphical mode → the grid;
  **menu mode → a real `NSMenu`** (`makeMarkNSMenu`, the AppKit twin of `markMenu`)
  popped up at the cursor, chrome-identical to the right-click menu and auto-closing
  natively. Right-click keeps its SwiftUI `contextMenu`; the two are kept in sync (noted).
- **Graphical shop 2nd item:** picking a shop on a tile that's already a shop fills the
  second-item slot; a third replaces the primary (`applyShopHotkeySmart`).
- **Swordless-aware sword tooltips** in the graphical chooser.
- **Bigger dungeon pickers:** monster 30→34px (icon 22→26), floor-drop 34→38 (24→28).
- **"bow" → "beau"** for TTS (whole-word), so "get the bow off the coast" says /boʊ/.
- **Overworld enemies:** added octorok / peahat / leever (overworld-only; NOT in the
  dungeon picker), rendered from game-sprite GIFs via `OverworldEnemyGlyph`.
- **White-sword-item reminder → two tiers:** "Consider…" at 4–5 hearts, "Get the white
  sword item" once at 6+ (`.getSword2`).
- **Armos-item reminder (new):** periodic "Get the armos item" every 3 min while located
  but unobtained (`.getArmosItem`), under a new toggleable *Armos Item* category.

## Sign-offs
- [x] Analyst — every change traces to a specific user request; the graphical chooser is
      opt-in so default behavior is unchanged.
- [x] Architect — the NSMenu uses a closure-target wrapper retained via representedObject;
      new enemies/reminders are Codable-additive (save-safe). No new external I/O.
- [x] Data — enemy enum + reminder additions are beyond-reference but additive; parity
      tests updated to encode the deliberate deviations.
- [x] Backend — chooser reuses shared apply paths (`applyMark`/`applyShopHotkeySmart`);
      armos reminder derives from existing poll params (no signature change).
- [x] Frontend / UX — graphical grid reads faster than text (the user's ask); double-left
      menu now native. User-verified across the batch.
- [x] SDET — added: chooser layout + option persistence, enemy sprite-load, bow
      pronunciation, white-sword two-tier, armos periodic + suppression; parity tests
      updated. **719 tests pass.**
- [x] DevOps — no infra change; `swift build`/`swift test` clean; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-185); INDEX updated.

## Items to address (follow-ups)
- `markMenu` (SwiftUI, right-click) and `makeMarkNSMenu` (AppKit, double-left-click) are
  two definitions kept in sync by hand; unify if drift becomes a problem.
- Timeline not restored on save/load — separate bug, queued next.
