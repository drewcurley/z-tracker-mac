# Review: fix/timeline-actual-pickups — final (T-113)

**Status:** PASS — timeline reflects real pickups; hearts + bait added.

unanimous-consensus: T-113

## Sign-offs
- [x] Analyst — resolves reported issue #9 (phantom tiers, + dungeon/coast hearts,
      + bait). Bait/hearts are documented additions beyond the reference item list.
- [x] Architect — derivation reads the same authoritative per-item sources as
      `PlayerComputedStateSummary`; no new mutable state.
- [x] Data — each tier now keys on its own boolean (progress/starting/box holding
      that exact item id), matching the reference `MakeAll` per-item booleans; BU
      guard verified against `PlayerComputedStateSummary`.
- [x] Frontend — new events map to atlas icons (heart container, bait).
- [x] UX — no more phantom wood-arrow/blue-candle stamps; dungeon/coast hearts and
      bait now visible with sensible hover names.
- [x] Backend — poll call site threads `startingItems` + BU flag.
- [x] SDET — added `actualPickupsNoPhantomTier` + `heartsAndBait`; updated
      `currentEvents` to real flags. 471 tests pass; build clean.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — task filed (T-113); INDEX updated.

## Regression safety
- Singleton items, triforces, take-any hearts, OW series, and finish snapshot are
  unchanged. Only the tiered derivation changed (level → per-item), plus additive
  heart/bait events. Full suite green.

## Follow-up
- Per-box hover location ("Level 1 Box 1", issue #8) needs a box-location event
  model and is tracked separately.
