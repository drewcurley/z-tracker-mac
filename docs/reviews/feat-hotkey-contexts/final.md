# Review: feat/hotkey-contexts — final (T-168)
**Status:** PASS — hover-driven hotkey contexts + three new regions, user-QA'd over three rounds.
unanimous-consensus: T-168

## Blockers
_none remaining._

## Warnings — resolved during review
1. **Dungeon-item axes transposed.** The region was declared 3 cols (box) × 9 rows
   (dungeon), but the nine cards run horizontally in an `HStack` and each card's boxes
   stack vertically — so the arrows drove the data layout instead of the visual one.
   Now 9 × 3. The original test asserted only the grid *size*, which passes just as
   happily transposed; replaced with one asserting arrow semantics against the layout.
2. **Notes stole focus on arrival**, swallowing the cycle key used to pass through it.
   Reworked to park-then-type.

## Suggestions (not taken)
- Sync `hoverRegion` from the live pointer position each event rather than from
  enter/exit callbacks. Rejected: it would need a global mouse-position query per
  keystroke to buy a case (resting mouse re-asserting without movement) the tie-break
  rule deliberately decides the other way.

## Sign-offs
- [x] **Analyst** — scope matches the agreed plan (contexts only; smarts → T-169,
      discoverability → T-170). Mouse-warp descope recorded in the audit, not silently
      dropped.
- [x] **Architect** — no new permissions. The descope specifically avoids the
      Accessibility (TCC) grant synthetic clicks would have required.
- [x] **Data Engineer** — no schema or save-format change; focus state is transient.
- [x] **Backend Engineer** — dispatch order is explicit: globals (nav-only when parked
      on Notes) → typing → hint zones → hovered/cursor region.
- [x] **Frontend Engineer** — hover exit is region-guarded against enter/exit reordering;
      the new regions reuse the existing cyan cursor ring rather than inventing a look.
- [x] **UX Designer** — parked Notes shows the cursor ring before it takes focus, so the
      state is visible rather than inferred. Escape is fixed, not bindable, because a
      bindable exit hits the same swallowing problem it solves.
- [x] **SDET** — 654 tests (17 new). Covers hover-vs-cursor precedence, stale-exit
      guarding, dungeon-item arrow semantics, Notes park/type/escape, navigation-global
      survival, and the unshown-cursor guard. `HintZone` name round-trip asserts every
      zone is reachable, so no binding is dead.
- [x] **DevOps** — no infra, deps, or bundle changes.
- [x] **Review Coordinator** — T-168 filed; INDEX updated.
