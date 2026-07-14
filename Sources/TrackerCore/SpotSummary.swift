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
    /// One unique overworld location and whether it's been marked yet.
    public struct UniqueSpot: Equatable, Sendable {
        public let mark: OverworldTileMark
        public let found: Bool
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
    /// The quest's total money secrets by size.
    public let secretsTotal: SecretCounts
    /// How many of each size are currently marked on the overworld.
    public let secretsPlaced: SecretCounts

    /// Remaining secrets of each *known* size (total − placed, clamped ≥ 0).
    /// Placed-but-unsized secrets are surfaced via `secretsPlaced.unknown`.
    public var secretsRemaining: SecretCounts {
        SecretCounts(
            large: max(0, secretsTotal.large - secretsPlaced.large),
            medium: max(0, secretsTotal.medium - secretsPlaced.medium),
            small: max(0, secretsTotal.small - secretsPlaced.small)
        )
    }

    public static func compute(grid: OverworldGrid, quest: OverworldQuest) -> SpotSummary {
        var counts: [OverworldTileMark: Int] = [:]
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                counts[grid.mark(column: c, row: r), default: 0] += 1
            }
        }
        func has(_ m: OverworldTileMark) -> Bool { (counts[m] ?? 0) > 0 }

        var uniques: [UniqueSpot] = []
        for n in 1...9 { uniques.append(UniqueSpot(mark: .dungeon(n), found: has(.dungeon(n)))) }
        for n in 1...4 { uniques.append(UniqueSpot(mark: .anyRoad(n), found: has(.anyRoad(n)))) }
        for n in 1...3 { uniques.append(UniqueSpot(mark: .swordCave(n), found: has(.swordCave(n)))) }
        uniques.append(UniqueSpot(mark: .theLetter, found: has(.theLetter)))
        uniques.append(UniqueSpot(mark: .armos, found: has(.armos)))

        let placed = SecretCounts(
            large: counts[.secret(.large)] ?? 0,
            medium: counts[.secret(.medium)] ?? 0,
            small: counts[.secret(.small)] ?? 0,
            unknown: counts[.secret(.unknown)] ?? 0
        )
        // First-quest overworld: 3/7/4; second-quest overworld: 1/7/6
        // (`OverworldMapTileCustomization.fs:404`).
        let total = quest.isFirstQuestOverworld
            ? SecretCounts(large: 3, medium: 7, small: 4)
            : SecretCounts(large: 1, medium: 7, small: 6)

        return SpotSummary(uniques: uniques, secretsTotal: total, secretsPlaced: placed)
    }
}
