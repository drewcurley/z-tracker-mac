# Review: feat/bomb-droppers-enemy — final (T-217)

**Status:** PASS — a generic "Bomb Droppers" overworld enemy marker rendered as a plain bomb icon.
User QA'd and approved. Ships as notarized **v1.2.1**.

unanimous-consensus: T-217

## What shipped
- `MonsterDetail.bombDroppers` ("Bomb Droppers"), appended to `overworldEnemies`; overworld-only
  (absent from `allInPickerOrder`, so the dungeon monster picker is unchanged).
- Renders the plain `"Bomb"` game sprite via `OverworldEnemyGlyph`; `DungeonMonsterAtlas` returns nil
  for it (not on the dungeon sheet). Normal up-to-two enemy pairing applies.

## Sign-offs
- [x] Analyst — scope: one additive overworld marker, exactly as requested; no dungeon-side change.
- [x] Architect — a plain enum case (no associated value) → Codable stays back-compatible; old saves
      load, the new case round-trips.
- [x] Data — n/a (enum + view mapping only).
- [x] Backend — reuses the existing `toggleEnemy` up-to-two path; no new storage.
- [x] Frontend/UX — bomb icon is legible at tile size; offered in both the graphical scroll-up
      picker and the right-click enemies menu; overworld-only placement matches octorok/peahat/leever.
- [x] SDET — new glyph test (resolves to `"Bomb"`, not on the dungeon sheet); updated the enum-count,
      overworld-set, and picker/atlas exclusion invariants. **759 tests pass.**
- [x] DevOps — clean build/test; ships as notarized dual-arch DMGs + appcasts for v1.2.1.
- [x] Review Coordinator — T-217 filed; INDEX updated; VERSION → 1.2.1.

## Items to address (follow-ups)
- None.
