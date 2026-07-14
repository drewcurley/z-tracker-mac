# Review: feat/hdn-model-core — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Carries a **scope decision**
(splitting T-016) — reviewed below.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] No consumer yet toggles the model into HDN — `TrackerModel` always
      constructs a `.default` `DungeonTrackerInstance`. Wiring the existing
      `hideDungeonNumbers` toggle to construct an HDN instance is a small
      follow-up (belongs with T-016.3's UI work, since HDN also changes
      rendering). The model core is correct and tested independently.
- [ ] `finalBoxOf1Or4` still exists on the instance in HDN mode (unused);
      the reference throws if you access its equivalent. Harmless here — no
      HDN path references it — and left present to keep the type uniform.

## Suggestions (consider for polish)
- When T-016.3 wires HDN construction, also thread
  `startingItemsAndExtras.hdnStartingTriforcePieces` into
  `getTriforceHaves(hdnStartingTriforcePieces:)` at the call site.

## Agent Sign-offs
- [x] Analyst — **scope decision reviewed.** T-016 bundled a model core with
      two UI/rendering pieces (basement-stair metadata, label/color UI) that
      need a dungeon-tracker room-grid UI that doesn't exist. Splitting into
      T-016.1 (model, now) + T-016.2 + T-016.3 mirrors the T-013→T-016 and
      T-015 slicing. This PR is the model core exactly — no UI.
- [x] Architect — no security surface; the HDN branches are pure model logic
      switched on `kind`. DEFAULT paths untouched.
- [x] Data Engineer — the HDN branches are transcribed against
      `TrackerModel.fs`: box counts `[3×8, 2]` (`:695-699`), the `isComplete`
      HDN branch incl. the exact quest-dependent two-boxer whitelists
      `"123567"`/`"234567"` (`:800-806`), and `getTriforceHaves`'s
      label→index + starting-pieces logic (`:824-833`). The `labelChar`→piece
      mapping (`'1'…'8'` → `0…7`) matches `int d.LabelChar - int '1'`.
- [x] Backend — N/A (no server); a signature addition
      (`getTriforceHaves(hdnStartingTriforcePieces:)`) with a default keeps
      DEFAULT callers source-compatible.
- [x] Frontend — N/A (no UI this sub-task).
- [x] UX — N/A.
- [x] Test Engineer — 9 new HDN tests: box counts + 29-box flatten, no shared
      box, 3-box completion, 2-boxer whitelist in both quests, triforce-
      required, label→piece mapping, starting-pieces fold-in, and a
      regression that DEFAULT ignores the HDN argument. The full DEFAULT
      suite (T-013) still passes unchanged. 158/158 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-016.md` + T-016.1/.2/.3 task files updated; INDEX regenerated.

## Lens Sign-offs (scope-splitting decision)
- [x] PM — the model core is independently valuable and testable; deferring
      the UI pieces (which need a host UI) avoids blocking on unbuilt surface.
- [x] Builder — switching on `kind` keeps DEFAULT and HDN side-by-side and
      diffable against the reference's own `match`.
- Other lenses — N/A (internal model; the visible HDN feature is T-016.3).

## Regression safety
- Contracts touched = none (in-process model types). Reflected in docs = yes
  (`domain.md` § 6). Cross-repo consumers = none. Compatibility = additive:
  new `color`/`labelChar` fields, a defaulted `getTriforceHaves` argument,
  and HDN construction no longer precondition-failing. DEFAULT behavior
  unchanged (T-013 suite green).
- Full suite: 149/149 → 158/158, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- T-016.2 — `StairKind`/`BoxOwner`/`CurrentlyHasBasementStair`.
- T-016.3 — HDN labeling UI + overworld lettered-dungeon rendering (+ wiring
  `hideDungeonNumbers` to construct an HDN instance).
