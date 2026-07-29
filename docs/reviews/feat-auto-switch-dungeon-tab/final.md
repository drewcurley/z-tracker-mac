# Review: feat/auto-switch-dungeon-tab — final (T-184)

**Status:** PASS — marking an overworld tile as dungeon N now switches the dungeon
panel to level N (click / hotkey / voice). QA-approved on device ("looks good").

unanimous-consensus: T-184

## What shipped
- `OverworldMark.didPlaceDungeon(number, column:row:model:focus:)` — a single shared
  helper for the two side effects of placing a dungeon marker: set the location hint
  (existing) **and** `focus.selectedDungeonTab = number - 1`. It replaces the hint-only
  closure that was triplicated at the three single-tile call sites (click in
  `OverworldSectionView`, hotkey in `GlobalHotkeyDispatcher`, voice in
  `VoiceController`), so the paths stay identical (T-134 principle).

## Scope
- Single-tile placement only (the paths that funnel through `OverworldMark.apply`).
- Bulk placement is deliberately unaffected: `autoMapVanillaDungeons` and the spoiler
  importer write marks straight to the grid, so they don't thrash the tab through all
  nine dungeons.

## Sign-offs
- [x] Analyst — matches the request (click + voice; hotkey folded in for path parity);
      no scope creep. Bulk paths correctly left alone.
- [x] Architect — no new state or I/O; reuses the existing `placeDungeon` chokepoint and
      the existing `TrackerFocusState.selectedDungeonTab`.
- [x] Data — n/a (no schema); tab index is transient UI focus state.
- [x] Backend — DRY: three duplicated closures collapse into one helper, so the hint +
      tab-switch can't drift; out-of-range levels are guarded.
- [x] Frontend / UX — surfacing the just-found dungeon's map is the expected next action;
      user-verified across input methods.
- [x] SDET — `OverworldMarkApplyTests`: switches to the right tab + sets the hint; ignores
      out-of-range. **710 tests pass.**
- [x] DevOps — no infra change; `swift build`/`swift test` clean; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-184); INDEX updated.

## Items to address (follow-ups)
- None.
