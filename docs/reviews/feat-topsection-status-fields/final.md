# Review: feat/topsection-status-fields — final (T-035.1)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — routine display over
already-tested derived state (memory: review-rigor-tiering).

## Blockers
- none

## Warnings
- none.

## Agent Sign-offs
- [x] Analyst — scope: display the two dynamic status fields (OW spots left,
      gettable) — first slice of the T-035 top-section umbrella. No overlay work.
- [x] Architect — no security surface; reads existing `MapStateSummary` values.
- [x] Data Engineer — "gettable" = `owGettableLocations.trueCount`, which the
      compute already gates per capability + per quest; a test pins the exact
      counts the user described (raft opens 2 in 1Q; recorder opens 1 in 1Q,
      10 in 2Q). "OW spots left" = `owSpotsRemain`.
- [x] Backend — N/A.
- [x] Frontend — `statusReadout` in the chrome (spots left / gettable / Max
      Hearts); values re-derive each body eval from the `@Observable` model, so
      they track marks/items live. `gettableCount` extracted for testability.
- [x] UX — the readouts mirror the reference's "N OW spots left" / "N gettable"
      cluster; colored (orange / green) for scannability, with tooltips.
- [x] Test Engineer — 249→252: `gettableCount` wiring, raft +2 (1Q), recorder
      +1 (1Q) / +10 (2Q). On-device: 73 spots / 28 gettable on an empty first
      quest.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-035.md` (umbrella) + `tasks/T-035.1.md`
      filed; INDEX updated. No `docs/*` domain change.

## Regression safety
- Contracts touched = none. Additive readout + a pure helper. Full suite
  249→252, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- T-035.2 open-caves + rupee/money overlays (hover-preview + click-lock);
  T-035.3 Zones + Coords overlays; T-035.4 timer / Spot Summary / FQ-SQ.
