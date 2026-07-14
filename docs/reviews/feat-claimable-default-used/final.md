# Review: feat/claimable-default-used — final (T-056)

**Status:** PASS — small default-state tweak on T-054.

unanimous-consensus: T-056

## Sign-offs
- [x] Analyst — scope: claimable tiles default to used when marked. Matches how
      players mark (right after collecting). In scope.
- [x] Data — `OverworldGrid.setUsed(_:column:row:)` writes the same
      `extraData[rawIndex]` used-flag as `toggleUsed`, guarded to toggleable
      marks; a no-op otherwise.
- [x] Frontend — `applyMark` centralizes picker mark-setting and sets claimable
      marks used; the left-click toggle is unchanged.
- [x] UX — one fewer click for the common case; the toggle still lets you undo.
- [x] Test Engineer — `setUsed` test (set/clear on a claimable, no-op on a
      shop). 299/299. On-device: Take any dims on selection; left-click brightens.
- [x] Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-056); INDEX updated.

## Regression safety
- Additive: non-claimable marks route through `applyMark` unchanged (setUsed
  no-ops). Full suite 299/299, build clean debug + release.
