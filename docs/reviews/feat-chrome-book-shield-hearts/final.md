# Review: feat/chrome-book-shield-hearts — final (T-025.5)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Tier: routine UI over existing
model + a small model flag (memory: review-rigor-tiering).

## Blockers
- none

## Warnings (fix before next review)
- [ ] **Book-is-Atlas** and **Highlight-open-caves** chrome controls are not
      built — their consumers (dungeon-map reveal; the nothingable-cave
      locator-highlight) don't exist yet, so the toggles would be dead. Deferred
      rather than shipped as no-ops.

## Suggestions
- The Book/Shield swap only manifests where item slot 0 appears in a box/picker
  (and on the toggle's own icon); there is no standing slot-0 box, so it's most
  visible in the picker. Fine.

## Agent Sign-offs
- [x] Analyst — scope: the two chrome controls with real wired effects; the two
      dead-without-consumer controls explicitly deferred, not faked.
- [x] Architect — no security surface. New `isCurrentlyBook` model flag
      (default book) + a pure `ItemIconOptions` value; no new assets.
- [x] Data Engineer — `isCurrentlyBook` maps slot 0 (`ITEMS.bookOrShield`) to
      book/shield exactly per `CustomComboBoxes.fs:46`; a test asserts the two
      swaps (BU, book/shield) are independent. Max Hearts steps the existing
      `maxHeartsDifferential`; the readout reads the derived `playerHearts`.
- [x] Backend — N/A.
- [x] Frontend — generalized the per-box swap flag `wsmsReplacedByBU: Bool` →
      `ItemIconOptions` threaded via `model.iconOptions`; added `bookShieldToggle`
      (inverted binding: checked = shield) and a nested-`@Bindable`
      `MaxHeartsControl` (needed because `startingItemsAndExtras` is a `let`).
- [x] UX — the chrome now groups Swordless / Shield-instead-of-book / Max Hearts
      under a divider below the grid; icons on each toggle. Reads clearly.
- [x] Test Engineer — 247→249: book/shield swap (default = book), swordless swap
      unchanged under the new signature, and swordless+book independence.
      On-device: book→shield icon swap on the toggle; Max Hearts 3→4.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-025.5.md` filed; INDEX updated. No `docs/*`
      domain change (renders existing/immediate model state).

## Lens Sign-offs
- Local UI slice — full 7-lens not triggered.

## Regression safety
- Contracts touched = none externally. `TrackerModel` gains a defaulted
  `isCurrentlyBook` init param. The icon helper signature changed
  (`wsmsReplacedByBU:` → `options:`) — all call sites + tests updated; the
  resolved icons are identical for the default options.
- Full suite 247→249, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- Book-is-Atlas + Highlight-open-caves chrome (need their consumers).
- The full "Starting Items & Extra Drops" editor panel (weapons/utility rows) —
  the debug panel stands in for now.
