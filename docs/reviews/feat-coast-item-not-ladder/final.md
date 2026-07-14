# Review: feat/coast-item-not-ladder — final (T-028)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Tier: small, well-scoped model
rule (memory: review-rigor-tiering).

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- none.

## Suggestions (consider for polish)
- none.

## Agent Sign-offs
- [x] Analyst — scope: exactly one rule (coast box can't be the ladder), a
      user-requested improvement over the reference. Explicitly no other cross-
      box constraints.
- [x] Architect — no security surface. A pure predicate guard; identity check
      against the instance's own `ladderBox`.
- [x] Data Engineer — correctness rationale is sound (the coast item at F16 is
      reached via the ladder, so it can't be the ladder). Rule composes with
      the existing uniqueness/`maxUses` logic — a test asserts both hold
      together. Armos/white-sword boxes untouched.
- [x] Backend — N/A.
- [x] Frontend — one line in `canSelectItem`; the picker UI already keys its
      availability/greying off that function, so no view change needed.
- [x] UX — the coast picker now greys and blocks the ladder (verified on-
      device: dimmed there, full-opacity in other boxes), preventing an
      impossible selection.
- [x] Test Engineer — 234→236: ladder disallowed in `ladderBox`, still allowed
      in armos/white-sword/dungeon boxes, and composition with uniqueness (put
      the ladder in armos → gone for sword2 by uniqueness, still gone for coast
      by its own rule).
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-028.md` filed; INDEX updated; deliberate
      deviation recorded in memory `project_coast-item-not-ladder-rule`. This
      is a documented divergence from the 1:1 clone, not a porting error.

## Lens Sign-offs
- Small correctness rule from direct user feedback — full 7-lens not triggered.

## Regression safety
- Contracts touched = none (a stricter `canSelectItem` for one box/item pair;
  every other pair returns exactly as before). Save/load unaffected (the rule
  gates selection, not stored state).
- Full suite 234→236, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- none.
