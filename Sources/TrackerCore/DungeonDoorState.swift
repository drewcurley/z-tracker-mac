/// The state of a wall/door between two adjacent dungeon rooms (T-019.3).
/// Ported from `Dungeon.DoorState` (`Z1R_WPF/Dungeon.fs:19-35`). The raw values
/// (0–4) match the reference's `AsInt()` for the future save format.
///
/// There is deliberately no dedicated "bombable"/"locked"/"shutter" — the
/// reference uses `yellow`/`purple` as generic "other" markers (`DungeonData.fs:50`).
public enum DoorState: Int, CaseIterable, Sendable, Codable {
    case unknown = 0
    case no = 1
    case yes = 2
    case yellow = 3
    case purple = 4

    /// Left-click cycle order (`Door.Next`): unknown→yes→no→yellow→purple→unknown.
    public var next: DoorState {
        switch self {
        case .unknown: .yes
        case .yes: .no
        case .no: .yellow
        case .yellow: .purple
        case .purple: .unknown
        }
    }

    /// The reverse cycle (`Door.Prev`).
    public var prev: DoorState {
        switch self {
        case .unknown: .purple
        case .yes: .unknown
        case .no: .yes
        case .yellow: .no
        case .purple: .yellow
        }
    }

    /// Scroll-down quick-set (T-085): an as-yet **unknown** door jumps straight to
    /// gold, since green/red are already the left/right clicks — so all four states
    /// are one gesture from an unset door. A placed door cycles forward as usual.
    public var scrollDown: DoorState { self == .unknown ? .yellow : next }

    /// Scroll-up quick-set (T-085): an unknown door goes to purple (which is also
    /// where `prev` already lands), a placed door cycles back.
    public var scrollUp: DoorState { self == .unknown ? .purple : prev }

    /// Whether Link can pass through — `yes`, `yellow`, or `purple`
    /// (`Door.IsTraversible`). `unknown`/`no` block.
    public var isTraversible: Bool {
        self == .yes || self == .yellow || self == .purple
    }

    /// The reference click-toggle: set to `target`, or back to `unknown` if it's
    /// already `target` (`DungeonUI.fs:726-742` — left = yes, right = no,
    /// middle = yellow).
    public func toggled(to target: DoorState) -> DoorState {
        self == target ? .unknown : target
    }

    /// The reference door color as `0xRRGGBB` (`Dungeon.fs:13-17`), for rendering.
    public var rgb: Int {
        switch self {
        case .unknown: 0x1E1E2D
        case .no: 0x910000
        case .yes: 0x3C783C
        case .yellow: 0xA0A028
        case .purple: 0x8C1E8C
        }
    }
}
