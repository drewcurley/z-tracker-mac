# Review: feat/door-scroll-quickset — final (T-085)

**Status:** PASS — unknown-door scroll jumps to gold/purple for one-flick marking.

unanimous-consensus: T-085

## Sign-offs
- [x] Analyst — quick-logging polish the user asked for; scoped to door scroll.
- [x] Architect / Data / Backend — pure `DoorState` transition; no state/schema.
- [x] Frontend — two computed props replace the inline gesture math; scroll +
      shift-scroll share them.
- [x] UX — green/red (left/right) + gold/purple (scroll down/up) put all four door
      states one gesture from an unset door; placed doors still cycle.
- [x] SDET — 5 door-gesture tests (1 new): unknown→gold/purple, placed==next/prev.
- [x] DevOps — no infra change.
- [x] Review Coordinator — task filed (T-085); INDEX updated.

## Regression safety
- Placed-door cycling is unchanged (`scrollDown==next`, `scrollUp==prev` for all
  non-unknown states, asserted in the test). Build clean.
