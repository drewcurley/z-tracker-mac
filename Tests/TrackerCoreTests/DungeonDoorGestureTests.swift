import Testing
@testable import TrackerCore

/// T-019.8 (D3) — the door click-toggle + cycle logic and the map's unified
/// door accessor, ported from `DungeonUI.fs:717-748` and `Dungeon.fs:40-56`.
@Suite("Dungeon door gestures (T-019.8)")
struct DungeonDoorGestureTests {

    @Test("toggle sets the target, or clears to unknown if already set")
    func toggle() {
        #expect(DoorState.unknown.toggled(to: .yes) == .yes)
        #expect(DoorState.yes.toggled(to: .yes) == .unknown)   // left-click again clears
        #expect(DoorState.unknown.toggled(to: .no) == .no)
        #expect(DoorState.no.toggled(to: .no) == .unknown)
        #expect(DoorState.unknown.toggled(to: .yellow) == .yellow)
        // toggling to a different target from a set state just switches target
        #expect(DoorState.yes.toggled(to: .no) == .no)
    }

    @Test("next/prev cycle matches the reference order")
    func cycle() {
        // Next: unknown→yes→no→yellow→purple→unknown
        #expect(DoorState.unknown.next == .yes)
        #expect(DoorState.yes.next == .no)
        #expect(DoorState.no.next == .yellow)
        #expect(DoorState.yellow.next == .purple)
        #expect(DoorState.purple.next == .unknown)
        // Prev is the exact inverse
        for s in DoorState.allCases {
            #expect(s.next.prev == s)
            #expect(s.prev.next == s)
        }
    }

    @Test("unified door accessor round-trips on both axes independently")
    func mapDoorAccessor() {
        let map = DungeonRoomMap()
        map.setDoor(.yes, axis: .horizontal, col: 2, row: 3)
        map.setDoor(.no, axis: .vertical, col: 2, row: 3)
        #expect(map.door(.horizontal, col: 2, row: 3) == .yes)
        #expect(map.door(.vertical, col: 2, row: 3) == .no)
        // The two axes are separate storage — setting one doesn't disturb the other.
        #expect(map.horizontalDoor(col: 2, row: 3) == .yes)
        #expect(map.verticalDoor(col: 2, row: 3) == .no)
        // A different cell is untouched.
        #expect(map.door(.horizontal, col: 0, row: 0) == .unknown)
    }

    @Test("only yes/yellow/purple are traversible")
    func traversible() {
        #expect(!DoorState.unknown.isTraversible)
        #expect(!DoorState.no.isTraversible)
        #expect(DoorState.yes.isTraversible)
        #expect(DoorState.yellow.isTraversible)
        #expect(DoorState.purple.isTraversible)
    }
}
