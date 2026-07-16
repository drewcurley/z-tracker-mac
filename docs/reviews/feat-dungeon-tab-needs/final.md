# Review: feat/dungeon-tab-needs — final (T-084)

**Status:** PASS — per-dungeon "needs" markers on the dungeon tabs.

unanimous-consensus: T-084

## Sign-offs
- [x] Analyst — the "mark what the dungeon needs" request; scoped to the three
      reference tab markers. In scope.
- [x] Architect — pure derived flags in TrackerCore; no security surface.
- [x] Data — flags read room type + completion; match the reference conditions
      (Goriya present / fed, Bomb-Upgrade incomplete, NPC-hint incomplete).
- [x] Backend — no new state; computed from the existing room map.
- [x] Frontend — markers overlaid on the tab button (bait leading, two dots
      trailing), non-hit-testing so they don't block tab selection.
- [x] UX — matches the reference placement/colors; red dot gated on the book
      option; VoiceOver value describes the markers.
- [x] SDET — 438 tests pass (3 new: Goriya/fed, Bomb-Upgrade, NPC-hint). Markers
      render-verified on-device (temp seed, removed; `grep TEMP` clean).
- [x] DevOps — no infra change.
- [x] Review Coordinator — task filed (T-084); INDEX updated.

## Regression safety
- Markers are additive overlays shown only when a special room is present; tabs
  are otherwise unchanged. Full suite green; build clean.
