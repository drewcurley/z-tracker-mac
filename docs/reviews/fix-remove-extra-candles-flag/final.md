# Review: fix/remove-extra-candles-flag — final (T-034)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — a correction of a
T-031 mechanic per the user, who reversed an earlier statement. Bug-fix tier.

## Blockers
- none

## Warnings
- none.

## Agent Sign-offs
- [x] Analyst — scope: remove exactly the incorrect Extra Candles pieces (flag,
      toggle, wood→candle display+derivation); keep the correct 4-state take-any.
- [x] Architect — removes a model flag + a view; net simplification.
- [x] Data Engineer — `PlayerComputedStateSummary.compute` reverts to the
      reference rule (wood sword raises sword level); the `extraCandles` param is
      gone. `TakeAnyHeartState`'s four states are unchanged.
- [x] Backend — N/A.
- [x] Frontend — dropped `extraCandlesToggle` (chrome now has two toggles) and
      the wood-sword branch in `iconOverride`; the wood-sword box always shows a
      wood sword. Take-any 4-state rendering intact.
- [x] UX — the wood-sword box no longer misleadingly shows a candle; take-any
      caves still distinguish potion vs candle.
- [x] Test Engineer — removed the now-invalid `extraCandlesWoodToCandle` test;
      the 4-state take-any tests (cycle, raw values) remain and pass. 250→249.
      On-device: two toggles, take-any empty on fresh launch, potion/candle
      overlays still render.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-034.md` filed; INDEX updated; memory
      `project_extra-candles-deviation` rewritten (4-state kept, flag removed).

## Regression safety
- Contracts touched: `PlayerComputedStateSummary.compute` lost its defaulted
  `extraCandles` param (reverts to prior behavior); `TrackerModel` lost the
  `extraCandles` field. No external consumers. Full suite 250→249, no
  regressions. Builds clean (debug + release).

## Out of scope
- Layout work toward the accurate Windows-VM reference (separate future task).
