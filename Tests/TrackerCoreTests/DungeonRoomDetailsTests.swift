import Testing
@testable import TrackerCore

/// T-019.7 (D2b) — monster / floor-drop picker orders, the completed-room
/// darkening rule, and the middle-click circle/brightness behavior.
@Suite("Dungeon room details (T-019.7)")
struct DungeonRoomDetailsTests {

    @Test("monster picker order covers every monster exactly once, ending in Unmarked")
    func monsterOrderComplete() {
        let order = MonsterDetail.allInPickerOrder
        #expect(order.count == MonsterDetail.allCases.count)
        #expect(Set(order) == Set(MonsterDetail.allCases))
        #expect(order.last == .unmarked)
        #expect(order.count == 32)
    }

    @Test("floor-drop picker order covers every drop exactly once, ending in Unmarked")
    func floorDropOrderComplete() {
        let order = FloorDropDetail.allInPickerOrder
        #expect(order.count == FloorDropDetail.allCases.count)
        #expect(Set(order) == Set(FloorDropDetail.allCases))
        #expect(order.last == .unmarked)
        #expect(order.count == 9)
    }

    @Test("only bubbles / traps / others stay bright on a completed room")
    func darkenRule() {
        let stayBright: Set<MonsterDetail> = [.blueBubble, .redBubble, .other, .other2, .traps]
        for md in MonsterDetail.allCases where md != .unmarked {
            #expect(md.darkensWhenCompleted == !stayBright.contains(md))
        }
    }

    @Test("middle-click on a room without a floor drop toggles the circle")
    func middleClickTogglesCircle() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 2, row: 2)
        #expect(!map.isCircled(col: 2, row: 2))
        map.middleClick(col: 2, row: 2)
        #expect(map.isCircled(col: 2, row: 2))
        map.middleClick(col: 2, row: 2)
        #expect(!map.isCircled(col: 2, row: 2))
    }

    @Test("middle-click on a room with a floor drop toggles brightness, not the circle")
    func middleClickTogglesBrightness() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .doubleMoat, floorDropDetail: .triforce), col: 3, row: 3)
        #expect(map.room(col: 3, row: 3).floorDropAppearsBright)
        map.middleClick(col: 3, row: 3)
        #expect(!map.room(col: 3, row: 3).floorDropAppearsBright)
        #expect(!map.isCircled(col: 3, row: 3))   // circle untouched
        map.middleClick(col: 3, row: 3)
        #expect(map.room(col: 3, row: 3).floorDropAppearsBright)
    }
}
