# Review: feat/spot-summary-popout — final (T-199)

**Status:** PASS — the Spot Summary can now be popped out into its own live window. QA'd on
device ("looks good").

unanimous-consensus: T-199

## What shipped
- `Window("Spot Summary", id: SpotSummaryWindowID)` + `SpotSummaryWindowView(model:)` that
  recomputes the summary live from the model.
- An "Open in window" button in the existing Spot Summary popover.

## Scope (per user)
- Dropped the Remaining-Items popout (no such view exists) and the Max-Hearts hover (obvious;
  deliberately not in the main view). This closes the §2 "Progress popouts" item.

## Sign-offs
- [x] Analyst — scoped to the one wanted popout; the two dropped pieces recorded.
- [x] Architect — reuses the established breakout-window pattern; live view over shared
      `@Observable` model, no new state.
- [x] Frontend / UX — popout stays current as marks change; popover still available; verified.
- [x] SDET — no new logic (`SpotSummary.compute` already tested); **730 pass**.
- [x] DevOps / Data / Backend — n/a; clean build/test; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-199); INDEX updated.

## Items to address (follow-ups)
- None.
