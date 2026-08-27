# Review: feat/gated-item-defaults — final (T-214)

**Status:** PASS — gated items default to untaken (or block, for the magical sword) when the
player can't have reached them yet. User QA'd and approved. Ships as notarized **v1.1.2**.

unanimous-consensus: T-214

## What shipped
- `ItemAcquisitionGate` (TrackerCore): ladder gate for the coast item; **4**-heart minimum for the
  white-sword item (range 4–6); **10**-heart minimum for the magical sword (range 10–14).
- `BoxItemPicker`/`BoxView` `defaultAcquired` → a left-click marks *untaken* below the gate; wired
  at the overworld item prompt (coast/white-sword) and the Items-grid picker boxes.
- `ItemToggleBox` `canAcquire` → blocks turning the magical sword on below the gate (it's a plain
  toggle); the overworld magical-sword cave click is gated identically.

## Sign-offs
- [x] Analyst — thresholds use the user-confirmed range minimums; coast is a hard ladder gate.
- [x] Architect — gate logic centralized + pure (`PlayerComputedStateSummary` in, Bool out); no
      new model state; soft default for boxes, hard block only for the toggle (user's explicit choice).
- [x] Data — n/a (view/derivation only).
- [x] Backend — both marking entry points (overworld prompt + item grid) route through the same
      `defaultAcquired`; magical sword gated at toggle + cave click.
- [x] Frontend/UX — picker caption reflects the gate; below-gate defaults untaken; above-gate the
      user's clicks are trusted; boxes stay hand-overridable (player may not track everything).
- [x] SDET — `ItemAcquisitionGateTests` (ladder + 4/10 minimums). **753 tests pass.**
- [x] DevOps — clean build/test; notarized dual-arch DMGs + appcasts for v1.1.2.
- [x] Review Coordinator — T-214 filed; INDEX updated; VERSION → 1.1.2.

## Items to address (follow-ups)
- None.
