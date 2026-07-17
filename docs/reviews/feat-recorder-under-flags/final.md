# Review: feat/recorder-under-flags — final (T-104)

**Status:** PASS — recorder widget moved to Flags to reclaim vertical space.

unanimous-consensus: T-104

## Sign-offs
- [x] Analyst / UX — the recorder's new/unbeaten settings are seed flags, so Flags
      is a sensible home; frees height so the app fits 1440p.
- [x] Frontend — `RecorderInfoWidget` rendered in `SeedFlagsView` (threaded
      `playerState`/`mapState`); removed from `MapInfoView`.
- [x] SDET — no logic change; build clean; suite green.
- [x] Architect / Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-104); INDEX updated.

## Regression safety
- Pure relocation; the widget's behavior (destinations, toggles) is unchanged.
