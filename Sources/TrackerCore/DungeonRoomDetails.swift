/// Monster + floor-drop detail metadata for the room-detail pickers (T-019.7,
/// "D2b"), ported from the reference `MonsterDetail.All()` / `FloorDropDetail.All()`
/// (`DungeonRoomState.fs:164-167`, `:221-222`) and the completed-room darkening
/// rule (`:534-537`). Kept in the model so the picker grids and the darkening are
/// unit-testable independent of the SwiftUI view.
extension MonsterDetail {
    /// The reference monster picker order — the 8×4 grid; `unmarked` (clear) last.
    public static let allInPickerOrder: [MonsterDetail] = [
        .gleeok, .bow, .digdogger, .dodongo, .patra, .manhandla, .aquamentus, .moldorm,
        .blueLanmola, .blueWizzrobe, .blueDarknut, .redLynel, .polsVoice, .redGoriya, .gibdo, .rope,
        .vire, .keese, .zol, .gel, .stalfos, .wallmaster, .likelike, .blueMoblin,
        .other, .other2, .traps, .redTektite, .blueBubble, .redBubble, .rupeeBoss, .unmarked,
    ]

    /// Whether a completed room darkens this monster's icon. The reference darkens
    /// all except the bubbles, the "other" placeholders, and traps (`:534-537`) —
    /// those stay bright because they're persistent hazards, not clearable enemies.
    public var darkensWhenCompleted: Bool {
        switch self {
        case .blueBubble, .redBubble, .other, .other2, .traps: false
        default: true
        }
    }
}

extension FloorDropDetail {
    /// The reference floor-drop picker order — the 3×3 grid; `unmarked` (clear) last.
    public static let allInPickerOrder: [FloorDropDetail] = [
        .triforce, .heart, .otherKeyItem, .bombPack, .key, .fiveRupee, .map, .compass, .unmarked,
    ]
}
