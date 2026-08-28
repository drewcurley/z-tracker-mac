/// The "drop rooms" reference (T-219): which vanilla room **layouts** never contain a floor drop,
/// per dungeon. So a runner knows not to bother checking those rooms. Data transcribed from the
/// community reference chart (the same one zhelper shows); applies to both first- and second-quest
/// seeds. The room thumbnails are sliced from that chart and bundled as `droproom-*` images.
public struct DropRoom: Sendable, Equatable, Hashable {
    /// Display label (e.g. "Spiral Stair").
    public let name: String
    /// Bundled thumbnail resource name (a `droproom-*.png`).
    public let imageKey: String
    public init(name: String, imageKey: String) { self.name = name; self.imageKey = imageKey }
}

public enum DropRooms {
    // The 14 unique room layouts (color/shape is a property of the layout, not the level).
    public static let zelda = DropRoom(name: "Zelda", imageKey: "droproom-zelda")
    public static let threeRows = DropRoom(name: "3 Rows", imageKey: "droproom-threerows")
    public static let spikeTrap = DropRoom(name: "Spike Trap", imageKey: "droproom-spiketrap")
    public static let singleBlock = DropRoom(name: "Single Block", imageKey: "droproom-singleblock")
    public static let circleWall = DropRoom(name: "Circle Wall", imageKey: "droproom-circlewall")
    public static let spiralStair = DropRoom(name: "Spiral Stair", imageKey: "droproom-spiralstair")
    public static let gleeok = DropRoom(name: "Gleeok", imageKey: "droproom-gleeok")
    public static let maze = DropRoom(name: "Maze", imageKey: "droproom-maze")
    public static let tee = DropRoom(name: "T", imageKey: "droproom-tee")
    public static let diamondStair = DropRoom(name: "Diamond Stair", imageKey: "droproom-diamondstair")
    public static let single6 = DropRoom(name: "Single 6", imageKey: "droproom-single6")
    public static let fivePair = DropRoom(name: "Five Pair", imageKey: "droproom-fivepair")
    public static let pointlessMoat = DropRoom(name: "Pointless Moat", imageKey: "droproom-pointlessmoat")
    public static let grid = DropRoom(name: "Grid", imageKey: "droproom-grid")

    /// Rooms that never drop in **every** dungeon.
    public static let never: [DropRoom] = [zelda, threeRows, spikeTrap, singleBlock, circleWall]

    /// Additional never-drop rooms specific to a dungeon **number** (1…9), beyond `never`.
    public static func levelSpecific(dungeon n: Int) -> [DropRoom] {
        switch n {
        case 1: [spiralStair, gleeok, maze, tee, diamondStair, single6]
        case 2, 3, 6, 7, 8, 9: [fivePair, maze, pointlessMoat]
        case 4: [grid, diamondStair, fivePair, single6, spiralStair]
        case 5: [grid, diamondStair, gleeok, maze, spiralStair, fivePair, single6]
        default: []
        }
    }

    /// Every room that never drops in the given dungeon (1…9) = the universal set plus its level set.
    public static func neverDrop(dungeon n: Int) -> [DropRoom] {
        never + levelSpecific(dungeon: n)
    }
}
