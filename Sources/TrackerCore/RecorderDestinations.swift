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
