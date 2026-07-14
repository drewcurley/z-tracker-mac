# Review: feat/timer-lap — final (T-035.4)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers
- none

## Warnings (fix before next review)
- [ ] Spot Summary + FQ/SQ (the rest of the top-section cluster) aren't built —
      a T-035.5.
- [ ] The `TimelineView` refreshes ~30×/sec while the tracker is open; trivial
      for a small text, but worth remembering if the top section grows heavy.

## Agent Sign-offs
- [x] Analyst — scope: the run timer with the two user additions (milliseconds;
      an independent yellow groundhog lap). Spot Summary / FQ-SQ deferred.
- [x] Architect — no security surface. A self-contained `@Observable` timer
      owned by the main view; the reset button gains a `startLap()` call.
- [x] Data Engineer — elapsed is a pure function of an injected date; the lap is
      `mainElapsed − lapOrigin`, so pause/reset compose correctly. All covered.
- [x] Backend — N/A.
- [x] Frontend — `TimerView` uses `TimelineView(.periodic by: 0.03)` for smooth
      ms; main green/orange, lap yellow + smaller, shown only after a lap
      starts. Pause/Resume + Reset buttons.
- [x] UX — the main timer keeps running across a groundhog reset (as asked) with
      the lap timing that attempt; ms give speedrun-grade precision.
- [x] Test Engineer — 264→269: `hmsMillis` (incl. .042 ms + negative clamp),
      main counts, lap independence across two resets, pause freezes both,
      reset clears. On-device: main 17.680 / lap 12.088 post-reset.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-035.4.md` filed; INDEX updated. No `docs/*`
      domain change.

## Lens Sign-offs
- [x] Adopter — a millisecond run timer + a per-groundhog-attempt lap is exactly
      what routers/4+4 practice wants. Other lenses N/A.

## Regression safety
- Contracts touched = none. New timer type + view; `ItemProgressGridView` gains
  a required `timer` (updated at its one call site); the reset button adds one
  `startLap()` call. Full suite 264→269, no regressions. Builds clean.

## Out of scope (follow-ons)
- **T-035.5** Spot Summary + FQ/SQ. Timer persistence across save/load (with
  save/load).
