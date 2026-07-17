# Review: feat/armos-sword-item-prompt — final (T-106)

**Status:** PASS — Armos / White-Sword cave prompt for their item in place.

unanimous-consensus: T-106

## Sign-offs
- [x] Analyst — matches the reference's in-place item prompt for these two marks.
- [x] Frontend — `applyMark` sets `itemPrompt`; a per-tile `.popover` reuses
      `BoxItemPicker` for `armosBox`/`sword2Box`; deps threaded in.
- [x] UX — the prompt appears at the tile, right after marking (dispatched so the
      context menu closes first).
- [x] SDET — 465 tests; build clean; clean launch. The popover interaction is
      UI-driven — user QA.
- [x] Architect / Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-106); INDEX updated.

## Verification note
- Trigger logic (armos / swordCave(2) → prompt) is simple and build-verified; the
  context-menu→popover handoff uses a main-queue dispatch to avoid a dismiss race.
  On-device interaction deferred to QA (unstable display).

## Regression safety
- Additive: two new params + one popover + a trigger in `applyMark`. Full suite green.
