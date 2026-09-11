import Observation

/// A standalone record of shop stock + prices for a race (T-218), inspired by zhelper. Most runners
/// keep this in Notes today; this gives it structure. It is **not** linked to the overworld shop
/// marks — it's a manual scratchpad the commentator/runner fills in. Saved with the game.
///
/// Fixed shape per the randomizer: **4 shops × 3 item slots**, **2 potions**, **2 bomb upgrades at a
/// single shared price**, and **6 paid hints from two hint shops (3 each)**. Everything is optional
/// (blank = unknown).
@Observable
public final class ShopPriceRecord {
    /// One shop item slot: which staple it stocks (nil = empty) and its price (nil = unknown).
    public struct Slot: Codable, Sendable, Equatable {
        public var kind: ShopKind?
        public var price: Int?
        public init(kind: ShopKind? = nil, price: Int? = nil) { self.kind = kind; self.price = price }
    }

    /// One paid hint: its price (nil = unknown) and whether the runner has collected it.
    public struct Hint: Codable, Sendable, Equatable {
        public var price: Int?
        public var collected: Bool
        public init(price: Int? = nil, collected: Bool = false) { self.price = price; self.collected = collected }
    }

    public static let shopCount = 4
    public static let slotsPerShop = 3
    public static let hintShopCount = 2
    public static let hintsPerShop = 3

    /// `shops[shopIndex][slotIndex]` — 4 shops (SH1…SH4), 3 slots each.
    public var shops: [[Slot]]
    public var bluePotionPrice: Int?
    public var redPotionPrice: Int?
    /// The two paid bomb upgrades always cost the same, so one field covers both.
    public var bombUpgradePrice: Int?
    /// `hints[hintShopIndex][hintIndex]` — 2 hint shops, 3 hints each (6 total).
    public var hints: [[Hint]]
    /// The overworld shop tile (by screen coord) each slot follows (T-224), so editing that shop on
    /// the map updates the slot. `nil` = the slot isn't following a map shop (hand-entered, or its
    /// shop was consolidated into another slot as a duplicate).
    public var slotCoords: [OverworldScreenCoordinate?]

    public init() {
        shops = Array(repeating: Array(repeating: Slot(), count: Self.slotsPerShop), count: Self.shopCount)
        hints = Array(repeating: Array(repeating: Hint(), count: Self.hintsPerShop), count: Self.hintShopCount)
        slotCoords = Array(repeating: nil, count: Self.shopCount)
    }

    /// True when nothing has been recorded yet (used to keep old saves clean / tests honest).
    public var isEmpty: Bool {
        shops.allSatisfy { $0.allSatisfy { $0 == Slot() } }
            && bluePotionPrice == nil && redPotionPrice == nil && bombUpgradePrice == nil
            && hints.allSatisfy { $0.allSatisfy { $0 == Hint() } }
    }

    /// Clear every recorded value back to blank (map links included — a following sync re-links).
    public func clearAll() {
        shops = Array(repeating: Array(repeating: Slot(), count: Self.slotsPerShop), count: Self.shopCount)
        hints = Array(repeating: Array(repeating: Hint(), count: Self.hintsPerShop), count: Self.hintShopCount)
        bluePotionPrice = nil; redPotionPrice = nil; bombUpgradePrice = nil
        slotCoords = Array(repeating: nil, count: Self.shopCount)
    }

    /// Sync the 4 slots to the overworld shops (T-224). A slot follows one shop **instance** (by
    /// coord) and prefills its items; two shops are the **same** (consolidated to one slot) only when
    /// their item sets are **equal** — the game has many instances of each of its four shop types, so
    /// candle/shield and candle/meat/shield stay separate until both hold the *same* items.
    ///
    /// `shopItemsByCoord` maps each marked shop's screen coord → its items; `orderedCoords` is those
    /// coords in a stable order (used only to place a brand-new shop). Steps: release a slot whose
    /// shop is gone; update each followed slot's items from its shop (fill-empty, so typed
    /// items/prices survive); place each new, non-duplicate shop in a free slot; then consolidate any
    /// two slots that now hold equal item sets (merging prices, dropping the later slot).
    public func syncToMap(shopItemsByCoord: [OverworldScreenCoordinate: [ShopKind]],
                          orderedCoords: [OverworldScreenCoordinate]) {
        // 1) Release slots whose followed shop is no longer on the map.
        for i in slotCoords.indices where slotCoords[i].map({ shopItemsByCoord[$0] == nil }) == true {
            slotCoords[i] = nil
            shops[i] = Array(repeating: Slot(), count: Self.slotsPerShop)
        }
        // 2) Update each followed slot's items from its shop (fill-empty preserves typed data).
        for i in slotCoords.indices {
            guard let c = slotCoords[i], let items = shopItemsByCoord[c] else { continue }
            fillEmptyItems(slot: i, with: items)
        }
        // 3) Place each new shop that isn't already followed and isn't a duplicate of a followed one.
        for coord in orderedCoords where !slotCoords.contains(coord) {
            let items = shopItemsByCoord[coord] ?? []
            // A duplicate instance of an already-followed shop (equal item set) → don't take a slot.
            let isDuplicate = slotCoords.contains { $0.flatMap { shopItemsByCoord[$0] }.map { Set($0) == Set(items) } == true }
            if isDuplicate { continue }
            guard let free = slotCoords.firstIndex(where: { $0 == nil }) else { break }   // all four taken
            slotCoords[free] = coord
            fillEmptyItems(slot: free, with: items)
        }
        // 4) Consolidate two followed slots that now hold **equal** item sets (e.g. after an edit made
        //    them identical): merge the later into the earlier (prices too), then release the later.
        for i in 0..<Self.shopCount {
            guard slotCoords[i] != nil else { continue }
            let a = Set(shops[i].compactMap(\.kind))
            guard !a.isEmpty else { continue }
            for j in (i + 1)..<Self.shopCount {
                guard slotCoords[j] != nil, Set(shops[j].compactMap(\.kind)) == a else { continue }
                mergePrices(from: j, into: i)
                slotCoords[j] = nil
                shops[j] = Array(repeating: Slot(), count: Self.slotsPerShop)
            }
        }
    }

    /// Fill a slot's empty item cells with `items` not already present (listing order); never
    /// overwrites a filled cell, so typed items/prices survive.
    private func fillEmptyItems(slot: Int, with items: [ShopKind]) {
        let ordered = items.sorted {
            (ShopKind.allCases.firstIndex(of: $0) ?? 0) < (ShopKind.allCases.firstIndex(of: $1) ?? 0)
        }
        var present = Set(shops[slot].compactMap(\.kind))
        for item in ordered where !present.contains(item) {
            guard let empty = shops[slot].firstIndex(where: { $0.kind == nil }) else { break }
            shops[slot][empty].kind = item
            present.insert(item)
        }
    }

    /// Copy any price from the `from` slot into the matching-item cell of `into` that lacks one — so
    /// a price typed on a soon-to-be-consolidated duplicate isn't lost (same shop → same prices).
    private func mergePrices(from: Int, into: Int) {
        for cell in shops[from] where cell.price != nil && cell.kind != nil {
            if let target = shops[into].firstIndex(where: { $0.kind == cell.kind && $0.price == nil }) {
                shops[into][target].price = cell.price
            }
        }
    }

    /// Cycle a shop slot's item to the next staple (nil → arrow → … → shield → nil), preserving the
    /// price. Guards the indices so a malformed call is a no-op.
    public func cycleSlotKind(shop: Int, slot: Int) {
        guard shops.indices.contains(shop), shops[shop].indices.contains(slot) else { return }
        let all = ShopKind.allCases
        let current = shops[shop][slot].kind
        let next: ShopKind?
        if let current, let idx = all.firstIndex(of: current) {
            next = idx + 1 < all.count ? all[idx + 1] : nil
        } else {
            next = all.first
        }
        shops[shop][slot].kind = next
    }

    // MARK: Save / restore
    public struct State: Codable, Sendable {
        public var shops: [[Slot]]
        public var bluePotionPrice: Int?
        public var redPotionPrice: Int?
        public var bombUpgradePrice: Int?
        public var hints: [[Hint]]
        /// Per-slot map-shop link (T-224). Optional so pre-T-224 shop-price saves still decode.
        public var slotCoords: [OverworldScreenCoordinate?]? = nil
    }

    public var state: State {
        State(shops: shops, bluePotionPrice: bluePotionPrice, redPotionPrice: redPotionPrice,
              bombUpgradePrice: bombUpgradePrice, hints: hints, slotCoords: slotCoords)
    }

    public func restore(_ s: State) {
        // Normalize to the fixed shape so a save from a different (future) layout can't leave a
        // ragged grid the UI would index out of bounds.
        shops = Self.normalizedShops(s.shops)
        hints = Self.normalizedHints(s.hints)
        bluePotionPrice = s.bluePotionPrice
        redPotionPrice = s.redPotionPrice
        bombUpgradePrice = s.bombUpgradePrice
        let rawCoords = s.slotCoords ?? []
        slotCoords = (0..<Self.shopCount).map { rawCoords.indices.contains($0) ? rawCoords[$0] : nil }
    }

    private static func normalizedShops(_ raw: [[Slot]]) -> [[Slot]] {
        (0..<shopCount).map { shop in
            (0..<slotsPerShop).map { slot in
                raw.indices.contains(shop) && raw[shop].indices.contains(slot) ? raw[shop][slot] : Slot()
            }
        }
    }

    private static func normalizedHints(_ raw: [[Hint]]) -> [[Hint]] {
        (0..<hintShopCount).map { shop in
            (0..<hintsPerShop).map { hint in
                raw.indices.contains(shop) && raw[shop].indices.contains(hint) ? raw[shop][hint] : Hint()
            }
        }
    }
}
