/// Pure gesture logic for a dungeon room's plain **left-click** (T-019.6, "D2a"),
/// mirroring the reference's mouse handler (`Z1R_WPF/DungeonUI.fs:1418-1450`).
/// Kept in the model so it's unit-tested independent of the SwiftUI view.
public enum DungeonRoomGesture {
    /// The room type an unmarked room is marked as by the left-click accelerator
    /// — the reference's `defaultRoom()` (`DungeonUI.fs:293`), `MaybePushBlock` by
    /// default. (The "prefer NonDescript" variant is a later More-Settings option.)
    public static let defaultRoom: RoomType = .maybePushBlock

    /// The outcome of a plain left-click: the new room state, and whether this
    /// click is the one that clears the dungeon's first-interaction flag.
    public struct LeftClickOutcome: Equatable, Sendable {
        public var room: DungeonRoom
        public var clearsFirstInteraction: Bool
        public init(room: DungeonRoom, clearsFirstInteraction: Bool) {
            self.room = room
            self.clearsFirstInteraction = clearsFirstInteraction
        }
    }

    /// Resolve a plain left-click on `room`. `isFirstInteraction` is true until
    /// the user first touches this dungeon's map (the reference's per-level
    /// `isFirstTimeClickingAnyRoom`); that first click drops the entrance.
    ///
    /// Order matches the reference exactly:
    /// 1. Touched dungeon + unknown room → accelerator: default room, completed.
    /// 2. First interaction → entrance (from south), completed.
    /// 3. Entrance room → cycle its arrow S→W→N→E→S.
    /// 4. Off-the-map → paint back to unmarked (recover an accidental toggle).
    /// 5. Otherwise → toggle completedness.
    public static func leftClick(on room: DungeonRoom, isFirstInteraction: Bool,
                                 defaultRoom: RoomType = defaultRoom) -> LeftClickOutcome {
        var wc = room
        if !isFirstInteraction && room.roomType.isNotMarked {
            wc.roomType = defaultRoom
            wc.isCompleted = true
            return LeftClickOutcome(room: wc, clearsFirstInteraction: false)
        }
        if isFirstInteraction {
            wc.roomType = .startEnterFromS
            wc.isCompleted = true
            return LeftClickOutcome(room: wc, clearsFirstInteraction: true)
        }
        if let next = room.roomType.nextEntranceRoom {
            wc.roomType = next
            return LeftClickOutcome(room: wc, clearsFirstInteraction: false)
        }
        if room.roomType.isOffMap {
            wc.roomType = .unmarked
            return LeftClickOutcome(room: wc, clearsFirstInteraction: false)
        }
        wc.isCompleted.toggle()
        return LeftClickOutcome(room: wc, clearsFirstInteraction: false)
    }
}
