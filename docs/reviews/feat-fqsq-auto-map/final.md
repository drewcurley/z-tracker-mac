# Review: feat/fqsq-auto-map — final (T-035.5)

**Status:** PASS

unanimous-consensus: T-035.5

## Summary
An "Auto-map dungeons…" menu (Info group) places the vanilla First/Second-Quest
dungeon locations on the overworld. `OverworldVanillaDungeons` holds the ported
coordinates; `TrackerModel.autoMapVanillaDungeons(secondQuest:)` clears prior
dungeon marks and sets `.dungeon(1…9)` at the quest's screens. Destructive, so
each choice confirms first.

## Sign-offs
- [x] Analyst — matches the user's stated behavior ("map vanilla locations,
      remove previous dungeon markers"). The reference's non-destructive circle
      overlay is intentionally not ported (no such layer here); deviation is
      documented in the source + task.
- [x] Architect — no security surface.
- [x] Data Engineer — coordinates transcribed verbatim from
      `OverworldData.fs:25-26`; clears only `.dungeon(_)` marks, leaves other
      marks intact; releases a take-any tile's Items-group slot before
      overwriting it (T-066 correctness preserved).
- [x] Backend — the operation is a pure model method; the view only triggers it.
- [x] Frontend — a `Menu` with two options; each routes through a
      `confirmationDialog` (destructive role).
- [x] UX — placed in the Info group near Spot Summary/resets; the confirm names
      the quest and warns it can't be undone.
- [x] Test Engineer — 4 tests: FQ coords, SQ coords, clears-prior-keeps-others,
      take-any slot release. 320/320 pass, build clean.
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-035.5); INDEX regenerated.

## Regression safety
- Additive model method + a new Info-group control; nothing else changes unless
  invoked, behind a confirm. Full suite 320/320. On-device: FQ auto-map placed
  all nine dungeons at the canonical screens, OW-spots 73→64.
