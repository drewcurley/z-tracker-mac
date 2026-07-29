# Review: fix/timeline-restore — final (T-186)

**Status:** PASS — the run timeline is now saved and restored. QA-approved on device
("appears to work").

unanimous-consensus: T-186

## Bug → cause → fix
Saving an active session restored marks/items but not the timeline. Cause:
`TrackerModel.State` omitted `timeline`, whose `acquiredAt` times are historical and
can't be re-derived. Fix: `TimelineModel` gets a `Codable` `State` (+ `state`/`restore`,
with `TimelineEvent`/`OverworldRemainingSample` made `Codable`); `TrackerModel.State`
gets an **optional** `timeline` field (older saves still decode with an empty timeline);
`snapshot`/`restore` carry it. The 1 Hz `recordTimeline` re-derives from current state,
so restored acquisition times are preserved (only newly-acquired events are stamped).

## Sign-offs
- [x] Analyst — scoped to the reported bug; no behavior change beyond persisting the timeline.
- [x] Architect — additive, optional field; no external I/O; backward-compatible save format.
- [x] Data — timeline round-trips through JSON; `[TimelineEvent: Int]` (non-string key)
      encodes as the standard key/value array and decodes back exactly.
- [x] Backend — restore order leaves `recordTimeline` to continue the series without
      clobbering restored times (existing events are skipped, not re-stamped).
- [x] Frontend / UX — n/a (no UI change); GameTimelineView now populates after a load.
- [x] SDET — round-trip test asserts timeline events/locations/latestSeconds; a new test
      strips the `timeline` key to prove pre-fix saves still decode. **720 tests pass.**
- [x] DevOps — no infra change; `swift build`/`swift test` clean; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-186); INDEX updated.

## Items to address (follow-ups)
- None.
