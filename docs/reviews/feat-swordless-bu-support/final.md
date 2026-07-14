# Review: feat/swordless-bu-support — final (T-025.4)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Mechanics grounded in the
reference (`IsWSMSReplacedByBU`, `CustomComboBoxes.fs:48`) + the z1r wiki, per
the no-invented-facts discipline; the user corrected an initial wood-sword→
candle confusion (that is the separate Extra Candles option, deferred to T-031).

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The rest of the item-grid chrome (book/shield, book-is-atlas,
      highlight-open-caves, max-hearts) is not built — their model flags/
      consumers don't exist yet (a later T-025.5).
- [ ] The OW *map tile* marks keep their sword-cave icons under BU (matches the
      reference, which only swaps the box-item domain + the magical-sword box);
      the swordless nature is conveyed by the tile-selector menu labels.

## Suggestions (consider for polish)
- none.

## Agent Sign-offs
- [x] Analyst — scope: swordless (WSMS→BU) toggle + sword-cave relabel + the
      two selector swaps, per the user's explicit scope choice. Extra Candles
      and the remaining chrome are out of scope (filed / noted).
- [x] Architect — no security surface. Pure icon-resolution helper +
      value-threaded `Bool`; the flag already lives on `TrackerModel`.
- [x] Data Engineer — the swap targets exactly `ITEMS.whiteSword` (box-item
      domain index 13, the reference's swapped index); a test asserts no other
      item — including the wood sword — is affected.
- [x] Backend — N/A.
- [x] Frontend — `ItemIconAtlas.icon(forItemIndex:wsmsReplacedByBU:)` threaded
      through `BoxView`/`BoxItemPicker` and the dungeon + coast boxes; the
      magical-sword item-grid box already swapped (T-025.1). `swordlessToggle`
      binds `$model.isWSMSReplacedByBU`. `OverworldMapView.swordCaveLabel` is a
      pure relabel + BU annotation.
- [x] UX — the swords→bombs toggle (with the `ws_ms_bomb_upgrade` sprite) reads
      clearly; sword-cave marks now say Wood Sword / White Sword Item / Magical
      Sword instead of "Sword cave N", and note Bomb Upgrade under swordless.
- [x] Test Engineer — 244→247: white-sword→BU only under BU, every other item
      (and the ladder as a spot-check) unchanged, and the three sword-cave
      labels off/on. On-device: toggle + magical-sword box swap + coast picker
      white-sword swap + wood sword untouched.
- [x] DevOps — no CI/asset change (reuses `icons7x7.png`'s `ws_ms_bomb_upgrade`
      slot). `swift build` (debug+release) + `swift test` clean.
- [x] Review Coordinator — `tasks/T-025.4.md` filed, `tasks/T-031.md` (Extra
      Candles) proposed; INDEX updated. No `docs/*` domain change.

## Lens Sign-offs
- Local UI feature from user request — full 7-lens not triggered.

## Regression safety
- Contracts touched = none. New defaulted params (`wsmsReplacedByBU`) on
  `BoxView`/`BoxItemPicker`/`DungeonCardView`; a new `isWSMSReplacedByBU` param
  on `OverworldMapView`; all default to `false` (prior behavior). `model` in
  `ItemProgressGridView` became `@Bindable` (same value, adds binding).
- Full suite 244→247, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- **T-031** Extra Candles (blue candle in wood sword cave + take-any caves).
- **T-025.5** remaining chrome (book/shield, book-is-atlas, highlight-open-
  caves, max-hearts panel).
