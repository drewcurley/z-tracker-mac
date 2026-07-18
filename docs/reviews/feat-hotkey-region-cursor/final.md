# Review: feat/hotkey-region-cursor — final (T-134, T-135)

**Status:** PASS — keyboard cursor + region cycle + per-region hotkey dispatch + a
right-half default binding scheme + a readable editor.

unanimous-consensus: T-135

## Scope
Part B of the hotkey feature: a movable keyboard cursor (T-134) and the region cycle /
per-region dispatch / default bindings / editor labels built on it (T-135). The
dungeon-item card region and click-at-cursor globals are explicitly deferred.

## Sign-offs
- [x] Analyst — scope is the cursor + the four marking regions the user asked to cycle
      (items ▸ overworld ▸ dungeon map ▸ blockers); dungeon-item card deferred per user.
- [x] Architect — cursor/region state on app-level `TrackerFocusState`; each region has
      a single shared apply (`OverworldMark`/`DungeonRoomMark`/`ItemBoxMark`/`BlockerRegion`)
      called by *both* the click path and the dispatcher, so the two can't drift.
- [x] Data — no schema change; marks route through existing model setters. Item-index ↔
      `Item_*` selector mapping verified against `ITEMS` (not assumed).
- [x] Backend — dispatcher routes a chord to the region matching the cursor; Global keys
      take precedence (scopes can't overlap a region). Back-compat alias for the old
      toggle selector id on import.
- [x] Frontend — cyan ring overlays per cell in each region; mouse hover-follow; reflow-safe.
- [x] UX — region keys act on the cursor cell identically to a click; PgDn/⇧PgDn cycle;
      defaults are right-half-only, tiered plain→Shift→Option, and dodge macOS-reserved
      plain F11/F12; editor shows human-readable key names.
- [x] SDET — logic unit-tested (cursor move/clamp/cycle/hover, each region's mark-apply
      and selector→action mapping, defaults completeness + conflict-freeness, keycode
      labels): **545 tests pass**. AppKit event dispatch is manual-QA'd on-screen
      (overworld dungeon-5, dungeon circle-moat, items recorder, blocker bomb, tab 5).
- [x] DevOps — no infra impact; pure app/package change.
- [x] Review Coordinator — tasks filed (T-134, T-135); INDEX updated.

## Regression safety
- The three dungeon-room pickers and the overworld click path were refactored to call
  the new shared apply; behavior is unchanged (same mutations), now reused by hotkeys.
- Default scheme is applied opt-in via `loadDefaults()` / the editor; no silent
  overwrite of a user's existing bindings on upgrade.

## Deferred (follow-ups)
- Click-at-cursor globals (LeftClick/RightClick/scroll) — would light up the item-grid
  toggle/heart cells and enable the dungeon-item card region.
- Dungeon-item card as a 5th cycle region (low priority per user).
