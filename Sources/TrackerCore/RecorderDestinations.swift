/// Which overworld screens are valid **recorder** (whistle) warp destinations
/// for the current state (T-035.7), ported from the reference's `recorderDests`
/// (`Z1R_Tracker/TrackerModel.fs:1606-1619`).
///
/// The set is empty unless the player has the recorder. For each dungeon level
/// 1–8 it is included only when `hasTriforce != toUnbeatenDungeons` (so by
/// default — `toUnbeatenDungeons == false` — only dungeons whose triforce you
/// already hold qualify; checking it inverts to not-yet-beaten dungeons). The
/// coordinate emitted is either the **discovered** map location
/// (`toNewDungeons == true`, and only if that dungeon has actually been located)
/// or the fixed **vanilla first-quest** screen (`toNewDungeons == false`).
public enum RecorderDestinations {
    /// One available destination: the screen plus the dungeon slot (0…7) it
    /// belongs to.
    public struct Destination: Hashable, Sendable {
        public let coordinate: OverworldScreenCoordinate
        public let slot: Int
        public init(coordinate: OverworldScreenCoordinate, slot: Int) {
            self.coordinate = coordinate
            self.slot = slot
        }
    }

    public static func compute(
        haveRecorder: Bool,
        dungeonTracker: DungeonTrackerInstance,
        hideDungeonNumbers: Bool,
        dungeonLocations: [OverworldScreenCoordinate?],
        toNewDungeons: Bool,
        toUnbeatenDungeons: Bool
    ) -> [Destination] {
        guard haveRecorder else { return [] }
        var result: [Destination] = []
        for tri in 0..<8 { // dungeon levels 1…8
            let (hasTri, idx) = triforceAndDungeonIndex(
                level: tri, dungeonTracker: dungeonTracker, hideDungeonNumbers: hideDungeonNumbers)
            guard hasTri != toUnbeatenDungeons else { continue }
            if toNewDungeons {
                // Discovered location — only if that dungeon is actually placed.
                if idx != -1, idx < dungeonLocations.count, let pos = dungeonLocations[idx] {
                    result.append(Destination(coordinate: pos, slot: idx))
                }
            } else {
                let v = OverworldVanillaDungeons.firstQuest[tri]
                result.append(Destination(coordinate: OverworldScreenCoordinate(x: v.column, y: v.row), slot: tri))
            }
        }
        return result
    }

    // MARK: - Info-area widget (T-081)

    /// One entry for the Info-area recorder widget: the dungeon **number** to warp
    /// to and its overworld coordinate *if* it has been located. Unlike `compute`
    /// (which drives the map highlight and — faithful to the reference — only emits
    /// *located* dungeons), the widget always lists an obtained-triforce dungeon;
    /// its `coordinate` is simply `nil` until you mark that dungeon on the map. This
    /// is the user's deliberate change (2026-07-16): the recorder destination is a
    /// function of which triforces you hold, not of whether you've placed the
    /// dungeon on the overworld yet.
    public struct WidgetEntry: Hashable, Sendable {
        /// The in-game dungeon numeral (1…8), or its HDN label numeral.
        public let dungeonNumber: Int
        /// The located overworld screen, or `nil` if not yet placed on the map.
        public let coordinate: OverworldScreenCoordinate?
        public init(dungeonNumber: Int, coordinate: OverworldScreenCoordinate?) {
            self.dungeonNumber = dungeonNumber
            self.coordinate = coordinate
        }
    }

    /// The obtained-triforce dungeons that the recorder can warp to, ascending by
    /// level. Same triforce filter as `compute` (`hasTri != toUnbeatenDungeons`),
    /// but the dungeon is included whether or not it's located — an unplaced
    /// dungeon yields a `nil` coordinate rather than being dropped.
    public static func infoEntries(
        dungeonTracker: DungeonTrackerInstance,
        hideDungeonNumbers: Bool,
        dungeonLocations: [OverworldScreenCoordinate?],
        toNewDungeons: Bool,
        toUnbeatenDungeons: Bool
    ) -> [WidgetEntry] {
        var result: [WidgetEntry] = []
        for tri in 0..<8 {
            let (hasTri, idx) = triforceAndDungeonIndex(
                level: tri, dungeonTracker: dungeonTracker, hideDungeonNumbers: hideDungeonNumbers)
            guard hasTri != toUnbeatenDungeons else { continue }
            let coord: OverworldScreenCoordinate?
            if toNewDungeons {
                coord = (idx != -1 && idx < dungeonLocations.count) ? dungeonLocations[idx] : nil
            } else {
                let v = OverworldVanillaDungeons.firstQuest[tri]
                coord = OverworldScreenCoordinate(x: v.column, y: v.row)
            }
            result.append(WidgetEntry(dungeonNumber: tri + 1, coordinate: coord))
        }
        return result
    }

    /// The entry the widget currently points at. When the user hasn't touched the
    /// arrows (`manualIndex == nil`) it's the lowest obtained-triforce dungeon
    /// (`entries.first`); otherwise it's `entries[manualIndex]`, wrapped. `nil`
    /// when there are no obtained-triforce dungeons.
    public static func selectedEntry(entries: [WidgetEntry], manualIndex: Int?) -> WidgetEntry? {
        guard !entries.isEmpty else { return nil }
        guard let manualIndex else { return entries.first }
        let i = ((manualIndex % entries.count) + entries.count) % entries.count
        return entries[i]
    }

    /// Whether the player holds level `level+1`'s triforce and which dungeon
    /// slot carries it. Ported from `doesPlayerHaveTriforceAndWhichDungeonIndexIsIt`
    /// (`TrackerModel.fs:1553-1567`): in HDN the level numeral is matched against
    /// each dungeon's assigned `labelChar`; otherwise the slot *is* the level.
    private static func triforceAndDungeonIndex(
        level: Int, dungeonTracker: DungeonTrackerInstance, hideDungeonNumbers: Bool
    ) -> (hasTri: Bool, idx: Int) {
        if hideDungeonNumbers {
            let levelChar = Character(String(level + 1))
            for j in 0..<8 where dungeonTracker.dungeon(j).labelChar == levelChar {
                return (dungeonTracker.dungeon(j).playerHasTriforce, j)
            }
            return (false, -1)
        } else {
            return (dungeonTracker.dungeon(level).playerHasTriforce, level)
        }
    }
}
