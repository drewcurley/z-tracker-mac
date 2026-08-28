import Testing
import TrackerCore
@testable import ZTrackerMac

/// Every drop-room layout must have its bundled thumbnail, or the window shows blank cells (T-219).
@MainActor
struct DropRoomImageTests {
    @Test("all 14 drop-room thumbnails load from the bundle")
    func allThumbnailsLoad() {
        let all: [DropRoom] = DropRooms.never
            + (1...9).flatMap { DropRooms.levelSpecific(dungeon: $0) }
        for room in Set(all) {
            #expect(DropRoomImage.image(room.imageKey) != nil, "missing thumbnail \(room.imageKey)")
        }
    }
}
