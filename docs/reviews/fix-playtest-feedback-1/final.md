# Review: fix/overworld-tile-rendering (playtest feedback 1) — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Mixed UI-polish + small model
addition, so Frontend/UX/Data lead.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The overworld dungeon/any-road number-size change was verified by code
      inspection (badge 0.82× tile + large font vs. the old 6pt in a 5px
      region), not by an automated screenshot — the SwiftUI context menu that
      sets a dungeon number didn't cooperate with synthetic clicks. The dark-
      tile darkening + floor hearts WERE screenshot-verified. User to confirm
      the number size when playing.
- [ ] Right-click on a box/picker item relies on the AppKit
      `RightClickCatcher`; logic is trivial but the click path is not
      automated here — user to confirm.

## Agent Sign-offs
- [x] Analyst — five scoped fixes from one playtest, each traced to the
      reference source (or an explicit aesthetic-license improvement). No
      scope creep.
- [x] Architect — no security surface. The item-uniqueness rule is a small,
      pure addition to `DungeonTrackerInstance` (no new state — counts on
      demand from box contents), matching the reference's `ChoiceDomain`
      max-use semantics without porting the stateful domain.
- [x] Data Engineer — `maxUses` (heart 9, else 1) verified against
      `ITEMS.itemNamesAndCounts`; floor-heart seeding (L1–8 only, `(14, NO)`)
      transcribed from `UI.fs:142-144`; applied at `selectQuest` (the
      reference's `makeAll` moment).
- [x] Backend — N/A.
- [x] Frontend — picker items dim + become non-interactive when unavailable;
      `onRightClick` via a background `NSViewRepresentable` lets normal taps
      pass through; overworld digits move to a centered badge; `.dontCare`
      renders terrain + a dark overlay.
- [x] UX — the dark-tile darkening (per the user's request) keeps the map
      legible; bigger numbers are readable at map scale; the picker now
      prevents impossible states (placing a second unique item) and reflects
      the 9-heart rule.
- [x] Test Engineer — 6 model tests: `maxUses`, unique-item exhaustion (+
      re-pick-own allowed), heart-allows-9, floor-hearts-off (L1–8 heart,
      L9 empty, 8 uses), floor-hearts-on (empty), and `selectQuest` seeding
      from `heartShuffle`. UI (disabling opacity, right-click) verified by
      inspection + the running app for the visual pieces. 216/216 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean; app
      builds + runs.
- [x] Review Coordinator — `tasks/T-022.md` filed; INDEX regenerated. (No
      `docs/*` domain change needed — these are fixes to already-documented
      features.)

## Lens Sign-offs
- [x] Adopter — the tracker now enforces item uniqueness + the heart rule and
      pre-seeds floor hearts, matching how the real app plays; the map reads
      better.
- Other lenses — N/A (polish + small rule).

## Regression safety
- Contracts touched = none (in-process model additions + UI). Cross-repo = none.
  Compatibility = additive; `selectQuest` now also seeds floor hearts.
- Full suite: 210/210 → 216/216, no regressions. `swift build` clean.

## Out of scope (follow-ons)
- Exact left/middle/right mouse on the box itself (middle = "don't want it");
  HDN letter labels; item-progress grid; blockers UI; room-grid view.
