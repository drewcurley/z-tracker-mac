# Review: feat/commentary-dual-pane-spot-summary — final (T-234)

**Status:** PASS — in commentary mode the Spot Summary shows a per-runner column each (with a
narrow-window stacked reflow in the breakout window). User tracked a live session with it and
approved. Ships as notarized **v1.2.10**.

unanimous-consensus: T-234

## What shipped
- Dual-pane Spot Summary when commentary mode is on: two columns (one per runner, name on a color
  chip, divider between), each tallying only the spots that runner has been shown; single-pane when
  commentary is off.
- Breakout window reflows side-by-side ↔ stacked by available width, scaling in both layouts.

## Sign-offs
- [x] Analyst — matches the request and the two follow-up clarifications (per-runner *tallies*, not
      just duplicated fields; narrow-window stacking). Scope decisions (global collected-state,
      both-seen counts in both columns) recorded and user-accepted.
- [x] Architect — no model/persistence change; reuses existing `CommentaryLayer` per-coordinate
      knowledge and the commentary hex→Color visuals; the compute filter is a pure closure param.
- [x] Data — n/a.
- [x] Backend — `SpotSummary.compute` gains a default-true `includeCell` filter (existing callers
      unchanged); dual content computed by calling it once per runner.
- [x] Frontend/UX — reuses `OverworldMarkIcon` and the runner color chips for a consistent visual
      language; responsive stacking mirrors the established dungeon-band pattern; inline popover
      correctly stays side-by-side (not resizable).
- [x] SDET — `SpotSummaryTests.perRunnerFilter` covers all/subset/none filtering. **792 tests pass**
      (full suite green, image atlas suite included since T-233).
- [x] DevOps — clean build/test; ships as notarized dual-arch DMGs + appcasts for v1.2.10.
- [x] Review Coordinator — T-234 filed; INDEX + CHANGELOG (1.2.10) updated; VERSION → 1.2.10.

## Items to address (follow-ups)
- Possible future option: a per-runner *collection* notion so "collected" dimming could be
  per-runner too — deferred; the model has no such state and the user accepted global dimming.
