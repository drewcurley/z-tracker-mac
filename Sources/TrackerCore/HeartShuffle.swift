/// The Heart Shuffle seed option (T-212) — a 3-way flag matching the randomizer's choices:
///
/// - `.off`   — hearts are **not** shuffled: each of dungeons 1–8 carries a Heart Container as
///   its known-but-unobtained floor item (the reference default).
/// - `.intra` — each dungeon's heart is shuffled **within that same dungeon**. It isn't
///   pre-placed, but it's guaranteed to be one of that dungeon's own item slots — so once every
///   other slot in a dungeon is identified as a non-heart, the last slot *must* be the heart and
///   the tracker fills it in (dimmed, untaken).
/// - `.full`  — hearts are shuffled into the **global** item pool (the old `heartShuffle == true`
///   behavior): each dungeon gains an extra floor-item slot and its heart could be anywhere.
///
/// Was a `Bool` (off/on) through T-211; the custom `Codable` below keeps old saves loading —
/// a stored `false`/`true` decodes to `.off`/`.full`.
public enum HeartShuffle: String, Codable, CaseIterable, Sendable {
    case off, intra, full

    /// Only `.off` pre-places a Heart Container in each dungeon's floor box; `.intra`/`.full`
    /// leave it empty (the heart lives in the item pool / is deduced).
    public var preplacesDungeonHearts: Bool { self == .off }

    /// Cycle order for the Flags tile: off → intra → full → off.
    public var next: HeartShuffle {
        switch self {
        case .off: return .intra
        case .intra: return .full
        case .full: return .off
        }
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        // Back-compat: a save written when this was a Bool decodes false→off, true→full.
        if let legacy = try? c.decode(Bool.self) { self = legacy ? .full : .off; return }
        let raw = try c.decode(String.self)
        self = HeartShuffle(rawValue: raw) ?? .off
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}
