# Shop & Price Tracker (T-218)

A breakout window for recording shop stock + prices in one place, inspired by zhelper. Most runners
keep this in the Notes section today; this gives it structure. **Breakout-only** — it's a
lesser-used feature and shouldn't clutter the main interface.

## What it records (user spec)
- **4 shops (SH1–SH4), 3 item slots each.** Each slot: pick one of the **8 shop staples** (arrow,
  bomb, book, candle, blue ring, meat, key, shield) + a price. Standalone manual record — **not**
  linked to the overworld shop marks.
- **Two potions:** blue-potion price, red-potion price.
- **Bomb upgrades:** exactly **2 per seed at the same price** → a single price field.
- **Hints:** **6 paid hints total, from two hint shops (3 each)** — each hint has its own price and a
  **collected** checkbox.

Everything is optional (blank = unknown). Saved with the game (a race runs long), back-compatible
with old saves.

## Info-panel change (make room without more vertical space)
The Info overlay-icon grid goes from **2×3 to 2×4**:
- **Top row, 4th icon:** opens this Shop & Price window.
- **Bottom row, 4th icon:** the Commentary-Mode quick toggle — the old "Commentary" *checkbox* becomes
  a **race-flag icon** matching the other overlay toggles (green when on).

## Model (TrackerCore)
`ShopPriceRecord` (`@Observable`, saved via `State`):
- `shops: [[Slot]]` — 4×3, `Slot { kind: ShopKind?; price: Int? }`
- `bluePotionPrice / redPotionPrice: Int?`
- `bombUpgradePrice: Int?`
- `hints: [[Hint]]` — 2×3, `Hint { price: Int?; collected: Bool }`
- Held on `TrackerModel`; `State?` optional in the snapshot so pre-T-218 saves decode.

## UI (ZTrackerMac)
`ShopPriceView` in a `Window(id: ShopPricesWindowID)`:
- Shops as a grid: SH1–SH4 rows × 3 (item-picker + price) cells. Each slot opens a picker on **left
  or right click** — a 2×4 icon grid (graphical) or a text list (menu), following the same
  `graphicalOverworldChooser` preference the overworld uses, plus Clear.
- A potions row (blue/red price), a bomb-upgrade price field, and a hints section (two labeled hint
  shops of 3, each price + collected checkbox).
- Numeric price entry; blanks allowed.

## Bomb-upgrade glyph (T-218)
The low-fidelity `wsMsBombUpgrade` atlas icon is replaced everywhere by `BombUpgradeGlyph` — the real
bomb sprite with a green outlined "+" — routed through `ItemGlyph`, so the swordless flag tile, the
white/magical-sword item boxes (swordless seeds), and the Shop & Price window all get it.

## Info-panel cart state
The cart icon tints green while the **window is open** (mirrors the Progress toggle via a transient
`model.showShopPricesWindow`), not based on whether the record holds data.

## Resolved
- Hints split **3 + 3** across the two hint shops — confirmed in QA.
