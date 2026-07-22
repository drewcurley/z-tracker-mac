import Observation

/// The 16×8 overworld map's tile-mark state (docs/domain.md § 4.5). Every
/// tile defaults to `.unmarked`. Stored as a flat array (row-major) rather
/// than a nested array so `@Observable` tracks single-tile writes without
/// needing to reassign an entire row.
@Observable
public final class OverworldGrid {
    public static let columnCount = 16
    public static let rowCount = 8

    private var tiles: [OverworldTileMark]

    /// Per-tile "extra data" key-value store, ported from the reference's
    /// `overworldMapExtraData` (`TrackerModel.fs:996-1011`): each of the 128
    /// tiles carries an array of `keyCount` ints (all 0 by default). Used for
    /// a 3-item shop's **second item** (key `OverworldTileMark.shopExtraDataKey`,
    /// value `0` = none, `1…8` in `toItem` format), `.theLetter`'s
    /// have-potion-letter toggle, and `.dontCare`'s un-revealed toggle. Stored
    /// flat (`tileIndex * keyCount + key`) so `@Observable` tracks single-cell
    /// writes.
    ///
    /// `keyCount` is `DARK_X + 1 = 36`, matching the reference's
    /// `Array.zeroCreate (DARK_X+1)` — the key is itself a mapSquare index.
    public static let extraDataKeyCount = OverworldTileMark.maxRawIndex + 1

    private var extraData: [Int]

    /// Per-tile link from a `.takeAny` tile to the Items-group take-any heart
    /// slot (`0…3`) it owns, or `-1` for none (T-066). Keeps each overworld
    /// take-any tile mapped to exactly one Items-group slot so their states stay
    /// in sync: re-marking the tile reuses its slot, and clearing/changing the
    /// tile frees it. Stored as its own flat array rather than in `extraData`
    /// (which mirrors reference `mapSquare` indices) since this link is a
    /// project-specific convenience with no reference analogue.
    private var takeAnySlotLinks: [Int]

    /// Per-tile enemy annotations (T-117, beyond the reference — user request):
    /// up to two `MonsterDetail`s per tile from the reduced overworld set, stored
    /// as 2 flat slots per tile (both `.unmarked` by default). This is map
    /// knowledge, so it survives a groundhog/routers reset.
    private var enemyPairs: [MonsterDetail]

    /// Per-screen "revealed" flags for custom-map fog-of-war (T-167): a screen starts
    /// hidden under fog and is revealed when it's first marked (or manually). Map
    /// knowledge — survives a groundhog reset and rides in the save.
    private var customMapRevealed: [Bool]

    /// Per-screen manually-placed fairy fountains for custom maps (T-167): on a custom
    /// overworld the vanilla fixed fairy spots don't apply, so the user places their
    /// own. Map knowledge; rides in the save.
    private var customFairySpots: [Bool]

    public init() {
        tiles = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount)
        extraData = Array(repeating: 0, count: Self.columnCount * Self.rowCount * Self.extraDataKeyCount)
        takeAnySlotLinks = Array(repeating: -1, count: Self.columnCount * Self.rowCount)
        enemyPairs = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount * 2)
        customMapRevealed = Array(repeating: false, count: Self.columnCount * Self.rowCount)
        customFairySpots = Array(repeating: false, count: Self.columnCount * Self.rowCount)
    }

    // MARK: Custom-map fog (T-167)
    public func isCustomMapRevealed(column: Int, row: Int) -> Bool {
        customMapRevealed[Self.index(column: column, row: row)]
    }
    public func setCustomMapRevealed(_ revealed: Bool, column: Int, row: Int) {
        customMapRevealed[Self.index(column: column, row: row)] = revealed
    }
    public func isCustomFairy(column: Int, row: Int) -> Bool {
        customFairySpots[Self.index(column: column, row: row)]
    }
    public func toggleCustomFairy(column: Int, row: Int) {
        let i = Self.index(column: column, row: row)
        customFairySpots[i].toggle()
        // Placing a fairy reveals its screen, exactly like placing a mark does — you
        // only know a fountain is there because you've been there. Removing one never
        // re-hides, again matching `setMark`.
        if customFairySpots[i] { customMapRevealed[i] = true }
    }

    /// A `Codable` snapshot of the full grid state for save/load (T-164). `restore`
    /// only accepts a snapshot whose arrays are the expected sizes, so a corrupt or
    /// mismatched save can't produce an out-of-bounds grid.
    public struct State: Codable, Sendable {
        var tiles: [OverworldTileMark]
        var extraData: [Int]
        var takeAnySlotLinks: [Int]
        var enemyPairs: [MonsterDetail]
        /// Optional so saves written before custom-map fog (T-167) still decode
        /// (a missing key → nil; a synthesized default value is *not* used for a
        /// missing key, so this must be optional, not a defaulted non-optional).
        var customMapRevealed: [Bool]?
        /// Optional for the same back-compat reason as `customMapRevealed`.
        var customFairySpots: [Bool]?
    }
    public var state: State {
        State(tiles: tiles, extraData: extraData, takeAnySlotLinks: takeAnySlotLinks,
              enemyPairs: enemyPairs, customMapRevealed: customMapRevealed,
              customFairySpots: customFairySpots)
    }
    /// Restore a saved snapshot; ignored (leaving the grid unchanged) if any array is
    /// the wrong size, guarding against corrupt saves.
    public func restore(_ s: State) {
        let n = Self.columnCount * Self.rowCount
        guard s.tiles.count == n,
              s.extraData.count == n * Self.extraDataKeyCount,
              s.takeAnySlotLinks.count == n,
              s.enemyPairs.count == n * 2 else { return }
        tiles = s.tiles; extraData = s.extraData
        takeAnySlotLinks = s.takeAnySlotLinks; enemyPairs = s.enemyPairs
        // Pre-T-167 saves have no reveal array → leave everything hidden (default).
        if let cmr = s.customMapRevealed, cmr.count == n { customMapRevealed = cmr }
        if let cfs = s.customFairySpots, cfs.count == n { customFairySpots = cfs }
    }

    public func mark(column: Int, row: Int) -> OverworldTileMark {
        tiles[Self.index(column: column, row: row)]
    }

    public func setMark(_ mark: OverworldTileMark, column: Int, row: Int) {
        tiles[Self.index(column: column, row: row)] = mark
        // Placing (not clearing) a mark reveals the screen's custom-map tile (T-167).
        // Clearing never re-hides it — once you've seen a screen it stays revealed.
        if mark != .unmarked { customMapRevealed[Self.index(column: column, row: row)] = true }
    }

    /// Reads a tile's extra-data value for `key` (`0…extraDataKeyCount-1`).
    /// Ported from `getOverworldMapExtraData` (`TrackerModel.fs:1000-1008`);
    /// this port omits the reference's `#if DEBUG` consistency assertion.
    public func extraData(column: Int, row: Int, key: Int) -> Int {
        extraData[Self.extraDataIndex(column: column, row: row, key: key)]
    }

    /// Writes a tile's extra-data value for `key`. Ported from
    /// `setOverworldMapExtraData` (`TrackerModel.fs:1009-1011`).
    public func setExtraData(_ value: Int, column: Int, row: Int, key: Int) {
        extraData[Self.extraDataIndex(column: column, row: row, key: key)] = value
    }

    /// Whether this tile's claimable thing has been marked **used** (collected)
    /// — T-054, only meaningful when the mark `isUsedToggleable`. Stored in
    /// `extraData` at the mark's own raw index (`extraData[state] == state`),
    /// exactly as the reference's `ToggleOverworldTileIfItIsToggleable`.
    public func isUsed(column: Int, row: Int) -> Bool {
        let mark = mark(column: column, row: row)
        guard mark.isUsedToggleable else { return false }
        let key = mark.rawIndex
        return extraData(column: column, row: row, key: key) == key
    }

    /// Toggle a claimable tile's used state (no-op if the mark isn't
    /// toggleable). Ported from `ToggleOverworldTileIfItIsToggleable`
    /// (`OverworldMapTileCustomization.fs:237-244`).
    public func toggleUsed(column: Int, row: Int) {
        let mark = mark(column: column, row: row)
        guard mark.isUsedToggleable else { return }
        let key = mark.rawIndex
        let current = extraData(column: column, row: row, key: key)
        setExtraData(current == key ? 0 : key, column: column, row: row, key: key)
    }

    /// Explicitly set a claimable tile's used state (no-op if not toggleable).
    /// Used when marking a claimable tile, which defaults to **used** (T-056).
    public func setUsed(_ used: Bool, column: Int, row: Int) {
        let mark = mark(column: column, row: row)
        guard mark.isUsedToggleable else { return }
        let key = mark.rawIndex
        setExtraData(used ? key : 0, column: column, row: row, key: key)
    }

    /// A shop tile's **second** item (T-060), or `nil` if none. Zelda shops
    /// carry two items: the primary is the `.shop(kind)` mark, the second is
    /// stored at `shopExtraDataKey` in the reference's toItem encoding
    /// (`1…8`; `0` = none) — the same slot `MapStateSummary` reads for
    /// "found shop".
    public func shopSecondItem(column: Int, row: Int) -> ShopKind? {
        let value = extraData(column: column, row: row, key: OverworldTileMark.shopExtraDataKey)
        guard (1...ShopKind.allCases.count).contains(value) else { return nil }
        return ShopKind.allCases[value - 1]
    }

    /// Set (or clear, with `nil`) a shop tile's second item.
    public func setShopSecondItem(_ kind: ShopKind?, column: Int, row: Int) {
        let value = kind.flatMap { ShopKind.allCases.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        setExtraData(value, column: column, row: row, key: OverworldTileMark.shopExtraDataKey)
    }

    /// A shop tile's items in the picker's listing order (`ShopKind.allCases`),
    /// for a stable left→right display regardless of which was chosen first
    /// (T-060). Empty when the tile isn't a shop.
    public func shopItems(column: Int, row: Int) -> [ShopKind] {
        guard case .shop(let first) = mark(column: column, row: row) else { return [] }
        var kinds = [first]
        if let second = shopSecondItem(column: column, row: row), second != first { kinds.append(second) }
        return kinds.sorted {
            (ShopKind.allCases.firstIndex(of: $0) ?? 0) < (ShopKind.allCases.firstIndex(of: $1) ?? 0)
        }
    }

    /// The Items-group take-any heart slot (`0…3`) this `.takeAny` tile is
    /// linked to (T-066), or `nil` if unlinked. Only meaningful on take-any
    /// tiles.
    public func takeAnySlot(column: Int, row: Int) -> Int? {
        let v = takeAnySlotLinks[Self.index(column: column, row: row)]
        return v >= 0 ? v : nil
    }

    /// Link (or unlink, with `nil`) a take-any tile to an Items-group slot.
    public func setTakeAnySlot(_ slot: Int?, column: Int, row: Int) {
        takeAnySlotLinks[Self.index(column: column, row: row)] = slot ?? -1
    }

    /// The take-any tile currently linked to Items-group slot `slot`, if any —
    /// the reverse lookup used to keep a tile's dim in sync when its heart box
    /// is edited directly (T-066).
    public func tileForTakeAnySlot(_ slot: Int) -> (column: Int, row: Int)? {
        guard let idx = takeAnySlotLinks.firstIndex(of: slot) else { return nil }
        return (column: idx % Self.columnCount, row: idx / Self.columnCount)
    }

    /// The set of Items-group slots currently owned by some take-any tile — a
    /// slot in here is not free to claim for a newly-marked tile (T-066).
    public func linkedTakeAnySlots() -> Set<Int> {
        Set(takeAnySlotLinks.filter { $0 >= 0 })
    }

    /// Clear every tile's **used** (claimed) state and take-any slot links,
    /// keeping the marks and other extra-data (shop items, etc.). Called by the
    /// groundhog/routers reset (T-058/T-066) — a replay re-collects everything,
    /// but the map knowledge stays.
    public func clearAllUsed() {
        for c in 0..<Self.columnCount {
            for r in 0..<Self.rowCount where isUsed(column: c, row: r) {
                setUsed(false, column: c, row: r)
            }
        }
        // Take-any tiles keep their `.takeAny` mark, but their claimed link back
        // to an Items-group slot is part of the run's collected state.
        takeAnySlotLinks = Array(repeating: -1, count: Self.columnCount * Self.rowCount)
    }

    /// Resets every tile to `.unmarked` and clears all extra-data — not
    /// itself a confirmed reference-app gesture, but a useful testing/reset
    /// hook.
    public func clearAll() {
        tiles = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount)
        extraData = Array(repeating: 0, count: Self.columnCount * Self.rowCount * Self.extraDataKeyCount)
        takeAnySlotLinks = Array(repeating: -1, count: Self.columnCount * Self.rowCount)
        enemyPairs = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount * 2)
    }

    // MARK: Enemy annotations (T-117)

    /// A tile's up-to-two enemies (both slots, including `.unmarked` placeholders).
    public func enemyPair(column: Int, row: Int) -> (MonsterDetail, MonsterDetail) {
        let base = Self.index(column: column, row: row) * 2
        return (enemyPairs[base], enemyPairs[base + 1])
    }

    /// A tile's enemies in display order, without the `.unmarked` placeholders.
    public func enemies(column: Int, row: Int) -> [MonsterDetail] {
        let (a, b) = enemyPair(column: column, row: row)
        return [a, b].filter { !$0.isNotMarked }
    }

    /// Toggle an enemy into the tile's up-to-two set (shared normalization with
    /// dungeon rooms). `.unmarked` clears both.
    public func toggleEnemy(_ m: MonsterDetail, column: Int, row: Int) {
        let base = Self.index(column: column, row: row) * 2
        let (a, b) = MonsterDetail.togglingPair(m, in: (enemyPairs[base], enemyPairs[base + 1]))
        enemyPairs[base] = a
        enemyPairs[base + 1] = b
    }

    private static func index(column: Int, row: Int) -> Int {
        precondition((0..<columnCount).contains(column), "column \(column) out of range")
        precondition((0..<rowCount).contains(row), "row \(row) out of range")
        return row * columnCount + column
    }

    private static func extraDataIndex(column: Int, row: Int, key: Int) -> Int {
        precondition((0..<extraDataKeyCount).contains(key), "extra-data key \(key) out of range")
        return index(column: column, row: row) * extraDataKeyCount + key
    }
}
