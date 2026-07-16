# Review: feat/dungeon-door-inference — final (T-019.12)

**Status:** PASS (end-to-end pending user confirmation) — the "Do door inference"
pref now auto-opens the inferred entry door on marking.

unanimous-consensus: T-019.12

## Sign-offs
- [x] Analyst — scope: wire the dead `doDoorInference` pref the user flagged. In
      scope (a listed dungeon-tracker behavior); focused on inference only, with
      pref-persistence noted as a separate follow-up.
- [x] Data — `inferEntryDoor` mirrors the reference candidate rule exactly
      (adjacent non-empty room, door ≠ `no`, exactly one, only `unknown`→`yes`)
      and the reference skips (Gannon/Zelda, second transport). Uses the existing
      door accessors; no schema change.
- [x] Frontend — one shared `markWithInference` drives the mouse left-click and
      the VoiceOver default action, so both infer consistently; gated by the
      option + the unmarked→marked transition captured in the view.
- [x] UX — auto-opening the sole possible entry matches the reference and saves a
      manual door mark; only ever sets `unknown`→`yes`, so it never overwrites a
      user's door.
- [x] SDET — 9 unit tests cover every branch (single/none/two candidates, `no`
      door excluded, already-set preserved, Gannon/Zelda, second transport,
      off-map neighbor, vertical vs horizontal). 395 total pass; clean debug +
      release. The marking gesture can't be synthesized here, so end-to-end
      (click → door greens) is flagged for the user (who reported the feature).
- [x] Architect — no security surface; local model mutation.
- [x] Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-019.12); INDEX updated.

## Regression safety
- Additive: a new pure map method + a 3-line view gate reusing verified pieces
  (`leftClick`, `setDoor`, `door` accessors). Inference only runs when the option
  is on and a room is freshly marked; off by default. Build clean; 395 tests pass.

## Follow-up
- Persist `doDoorInference` (and the other startup prefs) across launches — today
  only reminder settings persist, so the box must be re-checked each startup.
