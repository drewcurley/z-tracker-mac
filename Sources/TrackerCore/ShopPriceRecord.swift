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

    public init() {
        shops = Array(repeating: Array(repeating: Slot(), count: Self.slotsPerShop), count: Self.shopCount)
        hints = Array(repeating: Array(repeating: Hint(), count: Self.hintsPerShop), count: Self.hintShopCount)
    }

    /// True when nothing has been recorded yet (used to keep old saves clean / tests honest).
    public var isEmpty: Bool {
        shops.allSatisfy { $0.allSatisfy { $0 == Slot() } }
            && bluePotionPrice == nil && redPotionPrice == nil && bombUpgradePrice == nil
            && hints.allSatisfy { $0.allSatisfy { $0 == Hint() } }
    }

    /// Clear every recorded value back to blank.
    public func clearAll() {
        shops = Array(repeating: Array(repeating: Slot(), count: Self.slotsPerShop), count: Self.shopCount)
        hints = Array(repeating: Array(repeating: Hint(), count: Self.hintsPerShop), count: Self.hintShopCount)
        bluePotionPrice = nil; redPotionPrice = nil; bombUpgradePrice = nil
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
    }

    public var state: State {
        State(shops: shops, bluePotionPrice: bluePotionPrice, redPotionPrice: redPotionPrice,
              bombUpgradePrice: bombUpgradePrice, hints: hints)
    }

    public func restore(_ s: State) {
        // Normalize to the fixed shape so a save from a different (future) layout can't leave a
        // ragged grid the UI would index out of bounds.
        shops = Self.normalizedShops(s.shops)
        hints = Self.normalizedHints(s.hints)
        bluePotionPrice = s.bluePotionPrice
        redPotionPrice = s.redPotionPrice
        bombUpgradePrice = s.bombUpgradePrice
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
