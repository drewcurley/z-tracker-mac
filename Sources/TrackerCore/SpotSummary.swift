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
    /// the map) and, for claimable ones (armos, the letter), whether it's been
    /// **used** (collected, T-054).
    public struct UniqueSpot: Equatable, Sendable {
        public let mark: OverworldTileMark
        public let placed: Bool
        public let used: Bool
        public var displayName: String { mark.displayName }
        /// Whether the location is fully accounted for: a claimable spot once
        /// it's used, any other spot once it's placed.
        public var done: Bool { mark.isUsedToggleable ? used : placed }
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

    public static func compute(grid: OverworldGrid, quest: OverworldQuest) -> SpotSummary {
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
        for n in 1...3 { uniques.append(UniqueSpot(mark: .swordCave(n), placed: has(.swordCave(n)), used: false)) }
        uniques.append(UniqueSpot(mark: .theLetter, placed: has(.theLetter), used: usedAny(.theLetter)))
        uniques.append(UniqueSpot(mark: .armos, placed: has(.armos), used: usedAny(.armos)))

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

        return SpotSummary(uniques: uniques, secretsTotal: total,
                           secretsPlaced: secrets(counts), secretsUsed: secrets(used))
    }
}
