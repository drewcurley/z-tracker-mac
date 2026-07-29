# Review: feat/spoiler-room-maps — final (T-183)

**Status:** PASS — completes the one section T-181 deferred: the `LEVEL N MAP` ASCII
blocks now populate each dungeon's `DungeonRoomMap` (shape, transports, entrance,
doors). QA-approved on device ("looks good").

unanimous-consensus: T-183

## What shipped
- `SpoilerLog` map parser: `DungeonMap` (rooms + open doors + entrance, raw 0–15 × 0–7
  coords), parsed from raw whitespace-significant lines (CRLF-stripped). `*` room, `-`/`|`
  open doors, `< > v ^` entrance wall, letters **A–H = transport pairs 1–8**.
- `SpoilerApply.applyRoomMap`: normalizes the 16-wide canvas to the tracker's 8×8 —
  picks the 8-wide column window capturing the most rooms, off-maps every non-room cell
  so the outline reads, places transports + the entrance, opens the doors. The few
  outliers (always transport ends — teleporting, so column is cosmetic) relocate to the
  nearest free cell; the count is reported. Overwrites the map (spoiling is the point).
- Import panel reports "N room maps (M transports moved to fit)".

## Validation
A Swift smoke over the real seed's log matched an independent Python decode **exactly**:
L1–9 = 15/16/19/22/23/29/34/38/47 rooms, every transport pair complete (L9 = all 8,
A–H), one entrance each, 5 relocations total (L7:1, L8:2, L9:2).

## Sign-offs
- [x] Analyst — closes the T-181 follow-up; scope is the map section only, no creep.
- [x] Architect — pure parse over log text; total parser (bad geometry → fewer rooms,
      never a crash); apply overwrites atomically via `DungeonRoomMap.restore`.
- [x] Data — coordinate math + transport-pair semantics verified against the real 9 maps;
      map state round-trips through the existing save `State`.
- [x] Backend — window/normalize/relocate is deterministic (sorted iteration); transports
      committed via `setRoom` so the pair-of-two limit holds.
- [x] Frontend / UX — imported dungeons show outline + entrance icon + transport pairs +
      open doors; honest relocation count in the summary. User-verified.
- [x] SDET — crafted-fixture tests: raw-coord parse + apply (windowing, off-map shape,
      transports, outlier relocation, entrance, doors, summary). **708 tests pass.**
- [x] DevOps — no infra change; `swift build`/`swift test` clean; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-183); INDEX updated.

## Items to address (follow-ups)
- Walls between two known rooms import as `unknown` (only open doors set `.yes`) — could
  set `.no` for full connectivity if wanted.
- Outlier transport columns are approximate (≤2/dungeon); the pairs are exact.
