import Observation

/// App-level UI focus state shared with the hotkey dispatcher (T-133). Holding the
/// selected dungeon tab here (rather than as `@State` inside `DungeonMapView`) lets
/// Global `DungeonTab*` hotkeys switch tabs, and makes the selection survive the
/// dungeon-band reflow (which recreates the map view). The cursor subsystem (a later
/// Part-B phase) will add its state here too.
@Observable
@MainActor
final class TrackerFocusState {
    /// The visible dungeon tab: 0…8 = dungeons 1–9, 9 = the Summary tab.
    var selectedDungeonTab: Int = 0
}
