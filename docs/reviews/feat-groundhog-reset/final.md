# Review: feat/groundhog-reset — final (T-036)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. A **destructive** operation,
so reviewed with extra care on the reset scope + the safety confirmation.

## Blockers
- none

## Warnings (fix before next review)
- [ ] No save-before-reset (the reference saves first). This app has no
      save/load yet, so the confirmation dialog states the reset can't be
      undone. Add save-first when save/load lands.

## Suggestions
- The reset button lives in the always-visible chrome; the confirmation guards
  accidental clicks. Fine.

## Agent Sign-offs
- [x] Analyst — scope: the "remove inventory, keep maps" reset (user-raised),
      ported from the reference button. The overworld extra-data used-revert is
      explicitly deferred (that state isn't modeled yet).
- [x] Architect — no security surface; a model method + a confirmed button. The
      model was already architected for the keep-knowledge / reset-progress
      split, so this is orchestration, not new state.
- [x] Data Engineer — reset scope matches the reference: triforces off; box
      possession → NO keeping identity + SKIPPED; `playerProgress.resetAll()`;
      reminder reset. Starting items + marks + blockers kept. Two tests assert
      exactly the cleared vs preserved sets; a third checks idempotence.
- [x] Backend — N/A.
- [x] Frontend — `resetButton` → `confirmationDialog` (destructive + cancel);
      `@State confirmingReset`. Calls the model method on confirm.
- [x] UX — the dialog names what's removed (items/triforces/take-any) and what
      stays (marks/known locations), and warns it can't be undone. Verified
      on-device.
- [x] Test Engineer — 252→255: clears-inventory, preserves-knowledge (incl.
      box item identity + SKIPPED + starting items), idempotent-on-fresh.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-036.md` filed; INDEX updated. No `docs/*`
      domain change (a reset over existing model state).

## Lens Sign-offs
- [x] Adopter — enables groundhog/routers/4+4 practice (replay a seed keeping
      your knowledge) — a real speedrun-practice workflow. Other lenses N/A.

## Regression safety
- Contracts touched = none (a new method + a button). No existing behavior
  changed. Full suite 252→255, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- Save-before-reset (with save/load); reverting the overworld priced-secret
  used-state (with the claimed-state model / money overlay, T-035.2).
