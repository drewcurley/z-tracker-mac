import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Dungeon GRAB controller (T-083)")
@MainActor
struct DungeonGrabControllerTests {
    private func mapWithSegment() -> DungeonRoomMap {
        // A 2-room horizontal segment at (1,1)-(2,1).
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 1, row: 1)
        map.setRoom(DungeonRoom(roomType: .transport1), col: 2, row: 1)
        return map
    }

    @Test("toggle arms/disarms; disarming clears any grab")
    func toggle() {
        let g = DungeonGrabController()
        #expect(!g.isGrabMode)
        g.toggle(); #expect(g.isGrabMode)
        let map = mapWithSegment()
        g.handleClick(col: 1, row: 1, map: map)   // pick up
        #expect(g.hasGrab)
        g.toggle()                                 // disarm
        #expect(!g.isGrabMode)
        #expect(!g.hasGrab)
    }

    @Test("first click on a marked room picks up the whole contiguous segment")
    func pickUp() {
        let g = DungeonGrabController(); g.toggle()
        let map = mapWithSegment()
        g.handleClick(col: 1, row: 1, map: map)
        #expect(g.hasGrab)
        // Nothing moved yet (pick-up is non-destructive until drop).
        #expect(map.room(col: 1, row: 1).roomType == .doubleMoat)
        #expect(map.room(col: 2, row: 1).roomType == .transport1)
    }

    @Test("click on an empty room does not start a grab")
    func pickUpEmpty() {
        let g = DungeonGrabController(); g.toggle()
        let map = mapWithSegment()
        g.handleClick(col: 5, row: 5, map: map)   // empty
        #expect(!g.hasGrab)
    }

    @Test("second click drops the segment at the offset and prompts")
    func drop() {
        let g = DungeonGrabController(); g.toggle()
        let map = mapWithSegment()
        g.handleClick(col: 1, row: 1, map: map)   // pick up at anchor (1,1)
        g.handleClick(col: 3, row: 4, map: map)   // drop → delta (+2,+3)
        #expect(map.room(col: 1, row: 1).isEmpty)                 // cut from source
        #expect(map.room(col: 3, row: 4).roomType == .doubleMoat) // pasted
        #expect(map.room(col: 4, row: 4).roomType == .transport1)
        #expect(!g.isGrabMode)      // drop completes the grab (reference Abort)
        #expect(g.pendingConfirm)   // keep/undo prompt raised
    }

    @Test("Undo restores the pre-drop grid; Keep leaves it moved")
    func keepUndo() {
        let g = DungeonGrabController(); g.toggle()
        let map = mapWithSegment()
        g.handleClick(col: 1, row: 1, map: map)
        g.handleClick(col: 3, row: 1, map: map)
        g.undoChanges(map: map)
        #expect(map.room(col: 1, row: 1).roomType == .doubleMoat)  // back home
        #expect(map.room(col: 3, row: 1).isEmpty)
        #expect(!g.pendingConfirm)

        // Keep leaves a subsequent move in place.
        g.toggle()
        g.handleClick(col: 1, row: 1, map: map)
        g.handleClick(col: 3, row: 1, map: map)
        g.keepChanges()
        #expect(map.room(col: 3, row: 1).roomType == .doubleMoat)
        #expect(!g.pendingConfirm)
    }

    @Test("highlight: pick-up preview, source, and ok/warn drop targets")
    func highlight() {
        let g = DungeonGrabController(); g.toggle()
        let map = mapWithSegment()
        map.setRoom(DungeonRoom(roomType: .tee), col: 4, row: 1) // an obstacle

        // Before grab: hovering (1,1) previews its 2-room segment.
        g.hoverCell = .init(col: 1, row: 1)
        if case .preview = g.highlight(col: 2, row: 1, map: map) {} else { Issue.record("expected preview") }
        if case .none = g.highlight(col: 5, row: 5, map: map) {} else { Issue.record("expected none") }

        // After grab: source cells are pink; drop targets ok (empty) / warn (onto tee).
        g.handleClick(col: 1, row: 1, map: map)
        if case .source = g.highlight(col: 1, row: 1, map: map) {} else { Issue.record("expected source") }
        g.hoverCell = .init(col: 3, row: 1)   // delta (+2,0): (1,1)->(3,1), (2,1)->(4,1 = tee)
        if case .ok = g.highlight(col: 3, row: 1, map: map) {} else { Issue.record("expected ok") }
        if case .warn = g.highlight(col: 4, row: 1, map: map) {} else { Issue.record("expected warn") }
    }
}
