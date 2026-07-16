# Review: fix/old-men-count-total — final (T-074)

**Status:** PASS — OLD MEN readout now shows `X/Y` (marked / expected).

unanimous-consensus: T-074

## Sign-offs
- [x] Analyst — scope: a one-readout fix from user feedback. In scope.
- [x] Data — `DungeonOldManCounts` transcribes `oldManCounts1Q`/`2Q` verbatim
      (`DungeonData.fs:69-70`); `expected(...)` honors the second-quest-dungeons
      flag, matching `TrackerModel.GetOldManCount`.
- [x] UX — `X/Y` (marked / expected) tells you when a dungeon's old men are all
      found; HDN + unidentified slot shows just `X` (expected is unknowable),
      matching the reference display rule (`DungeonUI.fs:586-595`).
- [x] SDET — 2 tests for the counts (1Q/2Q vs reference); 420 total pass; clean
      debug + release. On-device: L1 shows `0/1`.
- [x] Frontend — `oldManText`/`expectedOldMen` computed in `DungeonMapView`; info
      strip text swapped. No other change.
- [x] Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-074); INDEX updated.

## Regression safety
- Display-only change to one readout + a new pure data enum. Build clean; 420 pass.
