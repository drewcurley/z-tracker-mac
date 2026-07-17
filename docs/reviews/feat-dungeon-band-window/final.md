# Review: feat/dungeon-band-window — final (T-123)

**Status:** PASS — dungeon band opens in its own window.

unanimous-consensus: T-123

## Sign-offs
- [x] Analyst — matches the request; reuses the established pop-out pattern.
- [x] Architect — `DungeonBandView` renders from the shared model, so inline and
      window stay in sync; window appear/disappear drives the placeholder flag.
- [x] Frontend — extracted view + shared `breakoutHeader`; inline placeholder.
- [x] UX — consistent with the timeline pop-out; "Bring back" restores inline.
- [x] Data / Backend / SDET / DevOps — no logic change; 493 tests pass; build clean.
- [x] Review Coordinator — task filed (T-123); INDEX updated.

## Regression safety
- Pure extraction + windowing; the band renders identically inline. Green.
