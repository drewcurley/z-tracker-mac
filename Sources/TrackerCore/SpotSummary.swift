/// The overworld "Spot Summary" (T-053) — what one-of-a-kind locations and
/// money secrets you still have left to find. Ported from the reference's
/// `MakeRemainderSummaryDisplay` (`OverworldMapTileCustomization.fs:332-474`):
/// the **unique** spots (each appears once on the map) are shown found/unfound,
/// and the **secrets** are counted against the quest's known totals.
///
/// Derived purely from the `OverworldGrid` marks + quest — our grid has no
/// cross-cell use-counting like the reference's `mapSquareChoiceDomain`, so
/// "found" here means "at least one tile is marked with it".
public struct SpotSummary: Equatable, Sendable {
    /// One unique overworld location: whether it's been **placed** (marked on
    /// the map) and, for claimable ones (armos, the letter, the three sword
    /// caves), whether it's been **used** (collected, T-054/T-065).
    public struct UniqueSpot: Equatable, Sendable {
        public let mark: OverworldTileMark
        public let placed: Bool
        public let used: Bool
        public var displayName: String { mark.displayName }
        /// Whether the location is fully accounted for. Dungeons and any-roads are
        /// done once **placed** (there's nothing to "collect"); the item-bearing
        /// uniques — the three sword caves, the letter, and the armos — are done
        /// once **used** (collected). `used` is populated correctly for the derived
        /// caves (sword2/sword3/armos) in `compute`, so this no longer keys off
        /// `isUsedToggleable` (T-110).
        public var done: Bool {
            switch mark {
            case .dungeon, .anyRoad: return placed
            default: return used
            }
        }
    }

    /// A non-unique overworld location type that has a known per-quest total —
    /// door repair, money-making game, hint shop, take-any, potion shop (the
    /// reference's "Non-Unique Locations" section, indices 28/29/32/33/34). Shops
    /// (bomb/candle/ring/meat/…) are deliberately absent: the reference tracks
    /// them as unbounded (max 999), so a "remaining" count isn't defined.
    public struct NonUniqueCount: Equatable, Sendable {
        public let mark: OverworldTileMark
        /// How many are marked on the overworld.
        public let marked: Int
        /// The quest's total number of this type.
        public let total: Int
        /// How many are still to find (clamped ≥ 0).
        public var remaining: Int { max(0, total - marked) }
        public var displayName: String { mark.displayName }
    }

    /// Counts of the money-secret sizes.
    public struct SecretCounts: Equatable, Sendable {
        public let large: Int
        public let medium: Int
        public let small: Int
        /// Placed-but-unsized secrets (only meaningful for `placed`).
        public let unknown: Int
        public init(large: Int, medium: Int, small: Int, unknown: Int = 0) {
            self.large = large; self.medium = medium; self.small = small; self.unknown = unknown
        }
    }

    /// The 18 unique spots, in display order: dungeons 1–9, any-roads 1–4,
    /// sword caves 1–3, the letter, the armos item.
    public let uniques: [UniqueSpot]
    /// The non-unique location types with per-quest totals (door repair, MMG,
    /// hint, take-any, potion), in the reference's display order.
    public let nonUniques: [NonUniqueCount]
    /// The quest's total money secrets by size.
    public let secretsTotal: SecretCounts
    /// How many of each size are currently marked on the overworld.
    public let secretsPlaced: SecretCounts
    /// How many of each size have been marked **used** (collected, T-054).
    public let secretsUsed: SecretCounts

    /// Remaining secrets of each size — total − **used** (collected), clamped
    /// ≥ 0. A secret marked on the map but not yet collected still counts as
    /// remaining. Placed-but-unsized secrets are surfaced via
    /// `secretsPlaced.unknown`.
    public var secretsRemaining: SecretCounts {
        SecretCounts(
            large: max(0, secretsTotal.large - secretsUsed.large),
            medium: max(0, secretsTotal.medium - secretsUsed.medium),
            small: max(0, secretsTotal.small - secretsUsed.small)
        )
    }

    /// - Parameters:
    ///   - armosDone: whether the armos item has been collected (`armosBox.isDone`).
    ///   - whiteSwordItemDone: whether the White-Sword-Item cave's item has been
    ///     collected (`sword2Box.isDone`).
    ///   - hasMagicalSword: whether the player has the magical sword.
    ///
    /// These three drive the "done" state of the armos / sword2 / sword3 uniques
    /// from model state rather than a map toggle (T-110), matching the reference
    /// tile dimming (`OverworldMapTileCustomization.fs:221-260`).
    public static func compute(grid: OverworldGrid, quest: OverworldQuest,
                               armosDone: Bool = false,
                               whiteSwordItemDone: Bool = false,
                               hasMagicalSword: Bool = false) -> SpotSummary {
        var counts: [OverworldTileMark: Int] = [:]
        var used: [OverworldTileMark: Int] = [:]
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                let m = grid.mark(column: c, row: r)
                counts[m, default: 0] += 1
                if grid.isUsed(column: c, row: r) { used[m, default: 0] += 1 }
            }
        }
        func has(_ m: OverworldTileMark) -> Bool { (counts[m] ?? 0) > 0 }
        func usedAny(_ m: OverworldTileMark) -> Bool { (used[m] ?? 0) > 0 }

        var uniques: [UniqueSpot] = []
        for n in 1...9 { uniques.append(UniqueSpot(mark: .dungeon(n), placed: has(.dungeon(n)), used: false)) }
        for n in 1...4 { uniques.append(UniqueSpot(mark: .anyRoad(n), placed: has(.anyRoad(n)), used: false)) }
        // Sword-cave 1 (wood) is a manual toggle; caves 2 (white-sword item) and 3
        // (magical sword) derive "done" from model state (T-110).
        uniques.append(UniqueSpot(mark: .swordCave(1), placed: has(.swordCave(1)), used: usedAny(.swordCave(1))))
        uniques.append(UniqueSpot(mark: .swordCave(2), placed: has(.swordCave(2)), used: whiteSwordItemDone))
        uniques.append(UniqueSpot(mark: .swordCave(3), placed: has(.swordCave(3)), used: hasMagicalSword))
        uniques.append(UniqueSpot(mark: .theLetter, placed: has(.theLetter), used: usedAny(.theLetter)))
        uniques.append(UniqueSpot(mark: .armos, placed: has(.armos), used: armosDone))

        func secrets(_ source: [OverworldTileMark: Int]) -> SecretCounts {
            SecretCounts(
                large: source[.secret(.large)] ?? 0,
                medium: source[.secret(.medium)] ?? 0,
                small: source[.secret(.small)] ?? 0,
                unknown: source[.secret(.unknown)] ?? 0
            )
        }
        // First-quest overworld: 3/7/4; second-quest overworld: 1/7/6
        // (`OverworldMapTileCustomization.fs:404`).
        let total = quest.isFirstQuestOverworld
            ? SecretCounts(large: 3, medium: 7, small: 4)
            : SecretCounts(large: 1, medium: 7, small: 6)

        // Non-unique location totals (reference `TrackerModel.fs:290-298` maxUses),
        // 1Q vs 2Q overworld.
        let firstOW = quest.isFirstQuestOverworld
        func nonUnique(_ m: OverworldTileMark, _ total1Q: Int, _ total2Q: Int) -> NonUniqueCount {
            NonUniqueCount(mark: m, marked: counts[m] ?? 0, total: firstOW ? total1Q : total2Q)
        }
        let nonUniques = [
            nonUnique(.doorRepair, 9, 10),
            nonUnique(.moneyMakingGame, 5, 6),
            nonUnique(.hintShop, 4, 4),
            nonUnique(.takeAny, 4, 4),
            nonUnique(.potionShop, 7, 9),
        ]

        return SpotSummary(uniques: uniques, nonUniques: nonUniques, secretsTotal: total,
                           secretsPlaced: secrets(counts), secretsUsed: secrets(used))
    }
}
