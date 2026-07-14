# Review: feat/dungeon-tracker-view — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The box popover sets "Have it" on item-tap and offers explicit
      Don't-want-it / Don't-have-it / Clear controls, rather than the
      reference's exact left/middle/right mouse mapping (macOS SwiftUI lacks a
      clean middle-click). Functionally equivalent (all three `playerHas`
      states + clear reachable); the exact 3-way-mouse is a later refinement.
- [ ] HDN letter labels on the numerals are not shown (T-016.3).

## Suggestions (consider for polish)
- The standalone boxes default to `.skipped` (an `✕`); that's the reference's
  default, but the `✕` reads as "actively skipped" — consider a subtler
  default treatment later.

## Agent Sign-offs
- [x] Analyst — scope is the dungeon item-tracker view: cards + boxes +
      picker + basement stairs + standalone boxes, rendering the already-built
      T-013/T-016 model with the T-020 sprites. HDN labels / item grid /
      blockers UI / room-grid view are explicitly deferred.
- [x] Architect — no security surface; a view over `@Observable` model
      objects (`@Bindable Box`/`Dungeon`), no new state ownership.
- [x] Data Engineer — box counts, basement stairs, completion, and triforce
      all read from the tested model (`dungeonTracker`); the picker writes via
      `Box.set`/`setPlayerHas` — no new derivation.
- [x] Backend — N/A (no server).
- [x] Frontend — cards use `@Bindable` for live updates; the box popover is a
      SwiftUI `.popover`; sprites via `ItemIconAtlas` with `.interpolation(.none)`
      (crisp pixel art). Top-aligned in a `ScrollView` so the tall tracker +
      map scroll.
- [x] UX — **aesthetic-license call:** the reference's cramped grid is
      re-laid-out as clean, bordered cards with clear per-state colors
      (green = have, gray = skipped, red/empty = don't-have) — more legible
      than the original while keeping the Zelda sprites. Verified legible
      against the reference side-by-side.
- [x] Test Engineer — `locatedDungeonIndices(in:)` extracted + unit-tested
      (empty / dungeon-marks→indices / non-dungeon-ignored). The rest is
      SwiftUI view code, **verified visually** on the running app (screenshots
      in the task's Verification): correct box layout + basement stairs, the
      picker rendering real sprites, and a full round-trip (set Ladder → box
      sprite + green border + the live reminder toast). 210/210 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean; the
      release app builds and runs.
- [x] Review Coordinator — process followed; `domain.md` § 6 note updated;
      `tasks/T-021.md` filed with screenshots' description; INDEX regenerated.

## Lens Sign-offs (the first big user-facing tracker surface)
- [x] Adopter — this is the tracker's core: click a dungeon box, pick the
      item, see it — and the app reacts (derived state + reminders update
      live). The most-used interaction now works.
- [x] Builder — extracting `locatedDungeonIndices` keeps at least the pure
      logic tested; the view is thin over the tested model + atlas.
- [x] Marketing — visibly a real Zelda tracker now, and (per the user)
      nicer-looking than the Windows original.
- Other lenses — N/A.

## Regression safety
- Contracts touched = none (new view + main-view wiring; the debug panel moved
  into a disclosure). Reflected in docs = yes. Cross-repo consumers = none.
  Compatibility = additive/UI-only.
- Full suite: 207/207 → 210/210, no regressions. `swift build` clean; app runs.

## Out of scope (tracked as follow-ons)
- Exact 3-way-mouse on the box; HDN letter labels (T-016.3); item-progress
  grid; blockers UI; dungeon room-grid view; T-015.6/.7.
