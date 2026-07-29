# Review: feat/spoiler-importer — final (T-181)

**Status:** PASS — imports a Z1R randomizer spoiler log and auto-marks the board:
overworld caves, L9 requirements + start spot, dungeon/named-cave items, swordless
+ heart-shuffle inference. Per-section checkboxes, remembered across opens. Room-map
ASCII is the one section still deferred (surfaced honestly in the result string).

unanimous-consensus: T-181

## What shipped
- `SpoilerLog` (TrackerCore) — section state-machine parser for the `*_log.txt`
  format: `SEED`, `LEVEL 9 ENTRY` (triforces + start screen), `ITEMS`, `CAVES`,
  `SHOP INFO`. Coord A–H×1–16 → (row,col). Unrecognized cave strings route to an
  `unmapped` list (never mis-marked).
- Cave-string → `OverworldTileMark` mapping (user-verified): sword caves, secrets,
  door-repair, MMG, potion/letter, shops (resolved via `SHOP INFO` notable item),
  take-any-road → `.anyRoad(0)` "?" unknown-order, take-any-one → `.takeAny`, the
  hint caves (secret-is-in / pay-me / old-man-at-grave) → `.hintShop`.
- `SpoilerApply` — writes the chosen `Sections` into the model:
  - **Overworld:** each cave + shop second item; **armos inference** — the log
    names the armos item but not its screen (and a randomizer glitch can drop the
    on-map marker), so whichever of D5/B13/C5/D14/E15 is the lone leftover is the
    armos.
  - **L9 + start:** triforce requirement appended to Notes; start spot set.
  - **Dungeon items:** floor items into each dungeon's boxes in log order; the
    three named caves (white-sword/coast/armos). **Swordless inferred** from any
    BOMB UPGRADE item. **Heart Shuffle** (log doesn't record it → import checkbox):
    OFF keeps the fixed box[0] heart and *keeps the log's own relocated heart
    entries*; ON places listed items then sweeps every empty slot to a heart.
- `.anyRoad(0)` "?" state — save-safe rawIndex 36; picker entry + "?" glyph in the
  map and spot summary.
- UI: `SpoilerImportView` sheet (NSOpenPanel default `~/Documents/ztracker`),
  launched from an "Import Spoiler…" button in the header.

## Sign-offs
- [x] Analyst — scope matches the locked spec (overworld · dungeon items · L9+start ·
      room maps checkbox), room maps honestly reported as deferred. No scope creep.
- [x] Architect — read-only over the log file; no network, no code execution; parser
      is total (unknown strings → unmapped, never a crash or mis-mark).
- [x] Data — mappings user-verified against the randomizer; coord math pinned by test
      (E8→0x47). Tile marks serialize as the Codable enum, so `.anyRoad(0)` is
      save-safe without touching rawIndex persistence.
- [x] Backend — apply is idempotent per section; item uniqueness respected; heart
      accounting corrected after QA (relocated "coast" heart into a dungeon is a real
      placement, not dropped).
- [x] Frontend / UX — one sheet, remembered checkboxes, honest post-import summary;
      overwrites are the point (user confirmed) and gated behind an explicit action.
- [x] SDET — fixture-driven parser + apply tests incl. armos ambiguity, heart-shuffle
      on/off, relocated-heart placement, unmapped routing. **707 tests pass.**
- [x] DevOps — no infra change; `swift build`/`swift test` clean; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-181); INDEX updated.

## Items to address (follow-ups)
- Dungeon room-map ASCII → the 8×8 room grids (the remaining `.roomMaps` section).
- Floor↔basement ordering the log can't express is corrected by the drag-to-swap
  gesture (T-182).
