# Review: feat/top-section-consistency — final (T-035.11)

**Status:** PASS

unanimous-consensus: T-035.11

## Summary
Placement-only consistency pass: resets moved right of the timer, the OW-spots
readout enlarged left of the timer, "Hide tile icons" folded into the overlay-
icon row (it was always the `.hideMarks` overlay), and "Auto-map dungeons" moved
under Flags. Movable pieces extracted into `StatusReadoutView`,
`ResetButtonsView`, `AutoMapDungeonsMenu`.

## Sign-offs
- [x] Analyst — exactly the user's requested moves; no behavior change.
- [x] Architect — no security surface.
- [x] Data Engineer — no model changes.
- [x] Backend — extracted views carry the same actions/confirmations verbatim.
- [x] Frontend — top strip is `readout · Spacer · timer · resets`; overlay row
      leads with `.hideMarks`; `SeedFlagsView` lost its now-unused `overlays`
      param.
- [x] UX — the most-glanced readout gets prominent left space; resets flank the
      timer; view toggles are unified as icons; config sits with Flags.
- [x] Test Engineer — placement-only; full suite 326/326, build clean; layout
      verified on-device.
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-035.11); INDEX regenerated.

## Regression safety
- Controls are the same views relocated (reset confirmations, auto-map confirm,
  overlay hover/lock all intact). 326/326, build clean. On-device: readout left,
  resets right of the timer, hide-icons first in the overlay row, auto-map under
  Flags.
