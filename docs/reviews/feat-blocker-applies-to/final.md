# Review: feat/blocker-applies-to — final (T-082)

**Status:** PASS — need/might-need kinds + the "applies to" panel and chips.

unanimous-consensus: T-082

## Sign-offs
- [x] Analyst — both requested features (need/might-need; applies-to). In scope;
      map/compass omission documented (no such cell in this tracker's cards).
- [x] Architect — model unchanged in shape (still stores 6 flags); no security surface.
- [x] Data — `blockersApplyingTo` filters to set kinds with the flag on; save
      JSON shape (`asJsonString`) unchanged and still tested.
- [x] Backend — chip resolution reuses `playerCouldBeBlockedByThis`; no new state.
- [x] Frontend — picker sections; right-click applies-to popover; chips as a
      bottom-leading overlay inside each box (clear box association) + a triforce row.
- [x] UX — need/might-need is explicit and labeled; the maybe gradient matches the
      box border everywhere; lime chip = "go back, you can clear it now".
- [x] SDET — 428 tests pass (2 new: Element indices, blockersApplyingTo). Chips
      render-verified on-device with a temp seed (removed; `grep TEMP` clean).
- [x] DevOps — no infra change.
- [x] Review Coordinator — task filed (T-082); INDEX updated.

## Deviation (deliberate)
- Map/compass applies-to elements are not exposed in the panel because this
  tracker's dungeon cards have no map/compass cell to chip; the model still keeps
  all six flags so save files round-trip identically.

## Regression safety
- `BoxView` chip params default to empty (coast box + other uses unaffected).
  Full build clean; full suite green.
