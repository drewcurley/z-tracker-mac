import Observation

/// How the commentary overlay is drawn (T-215), selectable in Settings.
public enum CommentaryEncoding: String, Codable, CaseIterable, Sendable {
    /// Small colored corner triangles — runner 1 top-left, runner 2 top-right.
    case pips
    /// A colored frame — one runner colors the whole edge; both splits it left/right.
    case border
}

/// Which runner(s) have discovered a given element, for **Commentary Mode** (T-215) — a
/// commentator-only layer over the shared tracker recording who *knows* each thing. Two
/// independent bits → four states: neither / runner 1 / runner 2 / both.
public struct CommentaryKnowledge: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let runner1 = CommentaryKnowledge(rawValue: 1 << 0)
    public static let runner2 = CommentaryKnowledge(rawValue: 1 << 1)
}

/// The Commentary-Mode knowledge overlay + the two runners' identities (T-215). Phase 1 covers the
/// **overworld** only; later phases add dungeon items / the item grid / room maps, reusing this.
/// Session state — saved with the game (a race runs long).
@Observable
public final class CommentaryLayer {
    /// Which runners know each element, keyed by a **namespaced string** so one store serves every
    /// surface: overworld screens (`ow:col,row`), dungeon item boxes (`box:dungeon,index`), and
    /// later the item grid and room maps. Absent key = neither (kept sparse).
    public private(set) var marks: [String: CommentaryKnowledge] = [:]

    /// Editable per-session runner identities.
    public var runner1Name: String = "Runner 1"
    public var runner2Name: String = "Runner 2"
    /// Hex colors (`#RRGGBB`) — TrackerCore is AppKit-free, so the view converts these to a color.
    public var runner1ColorHex: String = "#E03A3A"   // red
    public var runner2ColorHex: String = "#2F7FF0"   // blue

    public init() {}

    // MARK: Namespaced keys (one per surface)
    public static func overworldKey(column: Int, row: Int) -> String { "ow:\(column),\(row)" }
    public static func dungeonBoxKey(dungeon: Int, box: Int) -> String { "box:\(dungeon),\(box)" }
    /// A collectible-item-grid cell (toggle, take-any heart, or the coast/armos/white-sword box).
    public static func itemKey(_ id: String) -> String { "item:\(id)" }
    /// A dungeon room-map cell (dungeon index 0…8, col/row 0…7).
    public static func roomKey(dungeon: Int, col: Int, row: Int) -> String { "room:\(dungeon),\(col),\(row)" }
    /// A dungeon blocker box (dungeon index 0…8, slot 0…2).
    public static func blockerKey(dungeon: Int, slot: Int) -> String { "blk:\(dungeon),\(slot)" }

    // MARK: Generic access (any key)
    public func knowledge(_ key: String) -> CommentaryKnowledge { marks[key] ?? [] }

    /// Toggle one runner's knowledge of an element (⌥-click = runner1, ⌥-right-click = runner2).
    public func toggle(_ runner: CommentaryKnowledge, key: String) {
        var k = marks[key] ?? []
        k.formSymmetricDifference(runner)
        marks[key] = k.isEmpty ? nil : k
    }

    /// Clear every commentary mark (keeps runner names/colors).
    public func clearAll() { marks = [:] }

    // MARK: Overworld convenience (Phase 1)
    public func knowledge(column: Int, row: Int) -> CommentaryKnowledge {
        knowledge(Self.overworldKey(column: column, row: row))
    }
    public func toggle(_ runner: CommentaryKnowledge, column: Int, row: Int) {
        toggle(runner, key: Self.overworldKey(column: column, row: row))
    }

    // MARK: Save/restore
    public struct State: Codable, Sendable {
        /// key → raw knowledge bits.
        public var marks: [String: Int]
        public var runner1Name: String
        public var runner2Name: String
        public var runner1ColorHex: String
        public var runner2ColorHex: String
    }

    public var state: State {
        State(marks: marks.mapValues(\.rawValue),
              runner1Name: runner1Name, runner2Name: runner2Name,
              runner1ColorHex: runner1ColorHex, runner2ColorHex: runner2ColorHex)
    }

    public func restore(_ s: State) {
        marks = s.marks.mapValues { CommentaryKnowledge(rawValue: $0) }
        runner1Name = s.runner1Name; runner2Name = s.runner2Name
        runner1ColorHex = s.runner1ColorHex; runner2ColorHex = s.runner2ColorHex
    }
}
