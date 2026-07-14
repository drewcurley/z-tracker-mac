# Review: feat/hdn-number-chooser — final (T-050)

**Status:** PASS — completes HDN (chooser + triforce reference + two-boxer disable).

unanimous-consensus: T-050

## Sign-offs
- [x] Analyst — scope: the HDN dungeon-number chooser + the triforce reference
      diagram + (user-requested, beyond the reference) disabling an identified
      two-boxer's third box. Coherent completion of HDN (T-049 did toggles/labels).
- [x] Data — `TriforceReference` transcribes the F# `DrawTriforceMapCore` exactly
      (orderings `"12345678"` / `"13254687"`, 9 grid points, 8 sub-triangles).
      `Dungeon.identifiedAsTwoBoxer` reuses the completion whitelist
      (`"234567"` / `"123567"`) — a single source of truth, no drift.
- [x] Frontend — `DungeonNumberLabel`/`Picker` mirror the hint-picker pattern;
      the diagram draws each numbered piece as its own triangle (centroid-placed
      labels), selected number filled orange. `BoxView` gains a `disabled` state
      (dimmed, dashed, ⊘, no gestures) for the absent third box.
- [x] UX — the chooser carries the "unless you're certain" warning and the
      Mixed-Quest 7/8 caveat; the stacked diagrams give room for clear labels;
      disabling the third box stops players hunting a nonexistent item.
- [x] Backend — `labelChar` already drives triforce-piece placement
      (`getTriforceHaves`) and two-boxer completion, so identifying a dungeon
      now makes both work; disabling the box doesn't change completion (a
      two-boxer completes at 2/3).
- [x] Test Engineer — `TriforceReferenceTests` (orderings, positions,
      sub-triangles, centroids) + `identifiedAsTwoBoxer` (whitelist, assigned
      vs unassigned, DEFAULT-mode never flagged). 293/293. On-device: chooser +
      redrawn stacked diagrams + C's third box disabled after assigning 5.
- [x] Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-050); INDEX updated.

## Regression safety
- HDN-only surface; DEFAULT mode is untouched (`identifiedAsTwoBoxer` is false
  outside HDN, the chooser/label only render under HDN). Full suite 293/293,
  build clean debug + release.
