# Review: feat/shop-price-tracker — final (T-218)

**Status:** PASS — a standalone Shop & Price breakout window (shops/potions/bomb upgrade/hints), the
Info-panel 2×4 icon grid that makes room for it, and a real bomb-upgrade glyph everywhere. User QA'd
and approved. Ships as notarized **v1.2.2**.

unanimous-consensus: T-218

## What shipped
- `ShopPriceRecord` (TrackerCore, `@Observable`): 4×3 shop slots (staple + price), two potion prices,
  one bomb-upgrade price, 2×3 hints (price + collected). Saved via optional `State` on the snapshot;
  restore normalizes a ragged/short save to the fixed shape.
- `ShopPriceView` breakout: shop slots open a **left-or-right-click** picker — 2×4 graphical grid or
  text list per `graphicalOverworldChooser` — with Clear; potions/bomb-upgrade rows; hints as two
  labeled shops of 3 with collected checkboxes; Clear-all.
- Info panel: overlay grid 2×3 → 2×4; top-row cart opens/closes the window (green while open, via
  transient `showShopPricesWindow`); bottom-row race-flag replaces the Commentary checkbox.
- `BombUpgradeGlyph` (real bomb sprite + green "+") routed through `ItemGlyph`, so swordless tile,
  swordless item boxes, and the shop window all render it.

## Sign-offs
- [x] Analyst — matches the spec (standalone; 8 staples; 2 bomb upgrades same price; 6 hints as
      2 shops × 3 with prices + collected). Breakout-only per the user's "don't clutter the main UI".
- [x] Architect — one `@Observable` record, optional save field → old saves decode; `restore`
      normalizes malformed grids so the UI can't index out of bounds; window-open state is transient
      (not persisted), mirroring the Progress HUD.
- [x] Data — snapshot gains one optional Codable `State` (shops/potions/bomb/hints); round-trip +
      normalization tested.
- [x] Backend — bindings write straight into the record; the item picker reuses the overworld
      graphical/menu preference rather than a new setting.
- [x] Frontend/UX — left-or-right click opens the picker (set or change); graphical/menu follows the
      user's chooser setting; the cart-green bug (tracked data, not window) fixed to track the window;
      the low-fi bomb-upgrade icon replaced consistently everywhere it appears.
- [x] SDET — `ShopPriceRecordTests` (shape, clear, round-trip, ragged-restore, cycle helper).
      **766 tests pass.**
- [x] DevOps — clean build/test; notarized dual-arch DMGs + appcasts for v1.2.2.
- [x] Review Coordinator — T-218 filed; design doc updated (assumptions resolved); INDEX updated;
      VERSION → 1.2.2.

## Items to address (follow-ups)
- None.
