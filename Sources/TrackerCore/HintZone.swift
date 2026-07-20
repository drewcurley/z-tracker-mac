/// A hint as to which overworld region a dungeon / sword cave is located in
/// (T-039). Ported from `TrackerModel.HintZone` (`TrackerModel.fs:1299-1373`).
/// The `zoneChar` matches `OverworldData.owMapZone`'s letters, so a hint ties
/// into the Zones overlay's regions.
public enum HintZone: Int, CaseIterable, Sendable, Codable {
    case unknown = 0
    case deathMountain
    case lake
    case lostHills
    case river
    case grave
    case desert
    case coast
    case deadWoods
    case nearStart
    case forest

    /// The two-character label shown above a dungeon / sword box.
    public var twoChars: String {
        switch self {
        case .unknown: "UN"
        case .deathMountain: "DM"
        case .lake: "LK"
        case .lostHills: "LH"
        case .river: "RI"
        case .grave: "GR"
        case .desert: "DE"
        case .coast: "CO"
        case .deadWoods: "DW"
        case .nearStart: "ST"
        case .forest: "FO"
        }
    }

    public var displayName: String {
        switch self {
        case .unknown: "(Unknown)"
        case .deathMountain: "Death Mountain"
        case .lake: "Lake"
        case .lostHills: "Lost Hills"
        case .river: "River"
        case .grave: "Grave"
        case .desert: "Desert"
        case .coast: "Coast"
        case .deadWoods: "Dead Woods"
        case .nearStart: "Near Start"
        case .forest: "Forest"
        }
    }

    /// The zone for an `owMapZone` letter (the inverse of `zoneChar`), used to
    /// auto-set a dungeon's hint from the region of the screen it's placed on
    /// (T-039.1). Unknown letters (or `nil`) map to `.unknown`.
    public static func forZoneChar(_ char: Character?) -> HintZone {
        guard let char else { return .unknown }
        return HintZone.allCases.first { $0.zoneChar == char } ?? .unknown
    }

    /// The `owMapZone` letter for this zone (`_` for unknown), matching the
    /// Zones overlay (`AsDataChar`, `TrackerModel.fs:1337-1349`).
    public var zoneChar: Character {
        switch self {
        case .unknown: "_"
        case .deathMountain: "M"
        case .lake: "L"
        case .lostHills: "H"
        case .river: "R"
        case .grave: "G"
        case .desert: "D"
        case .coast: "C"
        case .deadWoods: "W"
        case .nearStart: "S"
        case .forest: "F"
        }
    }
}

/// Named indices into `TrackerModel.levelHints` (`TrackerModel.fs:1404`:
/// "0-8 is L1-9, 9 is WS, 10 is MS").
public enum HintTarget {
    /// Dungeon `1…9` → index `0…8`.
    public static func dungeon(_ number: Int) -> Int { number - 1 }
    public static let whiteSwordCave = 9
    public static let magicalSwordCave = 10
    public static let count = 11
}
