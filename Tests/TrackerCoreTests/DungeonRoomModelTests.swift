import Testing
@testable import TrackerCore

@Suite("Dungeon room model (T-019.3)")
struct DungeonRoomModelTests {

    // MARK: Enum counts + hot-key round-trips (for the future save format)

    @Test("enum case counts match the reference")
    func counts() {
        #expect(RoomType.allCases.count == 34)      // Unmarked + 33
        // Reference: Unmarked + 31 = 32. Beyond the reference we add 3 overworld-only
        // enemies (octorok / peahat / leever, T-185) and the generic bomb-droppers
        // marker (T-217) → 36.
        #expect(MonsterDetail.allCases.count == 36)
        #expect(FloorDropDetail.allCases.count == 9)
        #expect(DoorState.allCases.count == 5)
    }

    @Test("RoomType hot-key tokens round-trip; unknown → unmarked")
    func roomTypeHotKeys() {
        for r in RoomType.allCases {
            #expect(RoomType.fromHotKeyName(r.hotKeyName) == r)
        }
        // Exact reference tokens.
        #expect(RoomType.startEnterFromE.hotKeyName == "RoomType_StartEnterFromE")
        #expect(RoomType.hungryGoriyaMeatBlock.hotKeyName == "RoomType_HungryGoriyaMeatBlock")
        #expect(RoomType.transport3.hotKeyName == "RoomType_Transport3")
        #expect(RoomType.offTheMap.hotKeyName == "RoomType_OffTheMap")
        #expect(RoomType.fromHotKeyName("nonsense") == .unmarked)
    }

    @Test("MonsterDetail hot-key tokens round-trip; bow token, Gohma name")
    func monsterHotKeys() {
        for m in MonsterDetail.allCases {
            #expect(MonsterDetail.fromHotKeyName(m.hotKeyName) == m)
        }
        #expect(MonsterDetail.bow.hotKeyName == "MonsterDetail_Bow")   // internal name…
        #expect(MonsterDetail.bow.displayName == "Gohma")             // …display name
        #expect(MonsterDetail.rupeeBoss.hotKeyName == "MonsterDetail_RupeeBoss")
        #expect(MonsterDetail.fromHotKeyName("x") == .unmarked)
    }

    @Test("FloorDropDetail hot-key tokens round-trip")
    func floorDropHotKeys() {
        for f in FloorDropDetail.allCases {
            #expect(FloorDropDetail.fromHotKeyName(f.hotKeyName) == f)
        }
        #expect(FloorDropDetail.fiveRupee.hotKeyName == "FloorDropDetail_FiveRupee")
        #expect(FloorDropDetail.otherKeyItem.hotKeyName == "FloorDropDetail_OtherKeyItem")
    }

    // MARK: RoomType helpers

    @Test("isOldMan covers exactly the four NPC rooms")
    func isOldMan() {
        let oldMen: Set<RoomType> = [.oldManHint, .bombUpgrade, .lifeOrMoney, .hungryGoriyaMeatBlock]
        for r in RoomType.allCases {
            #expect(r.isOldMan == oldMen.contains(r))
        }
    }

    @Test("entrance rooms cycle S→W→N→E→S; non-entrances have no next")
    func entranceCycle() {
        #expect(RoomType.startEnterFromS.nextEntranceRoom == .startEnterFromW)
        #expect(RoomType.startEnterFromW.nextEntranceRoom == .startEnterFromN)
        #expect(RoomType.startEnterFromN.nextEntranceRoom == .startEnterFromE)
        #expect(RoomType.startEnterFromE.nextEntranceRoom == .startEnterFromS)
        #expect(RoomType.nonDescript.nextEntranceRoom == nil)
    }

    @Test("transportNumber maps Transport1…8 → 1…8, else nil")
    func transportNumber() {
        #expect(RoomType.transport1.transportNumber == 1)
        #expect(RoomType.transport8.transportNumber == 8)
        #expect(RoomType.chevy.transportNumber == nil)
    }

    // MARK: DoorState

    @Test("DoorState raw values, cycle, and traversibility")
    func doorState() {
        #expect(DoorState.unknown.rawValue == 0)
        #expect(DoorState.purple.rawValue == 4)
        // Next cycle: unknown→yes→no→yellow→purple→unknown
        #expect(DoorState.unknown.next == .yes)
        #expect(DoorState.yes.next == .no)
        #expect(DoorState.no.next == .yellow)
        #expect(DoorState.yellow.next == .purple)
        #expect(DoorState.purple.next == .unknown)
        // Prev is the inverse.
        for d in DoorState.allCases { #expect(d.next.prev == d) }
        // Traversible: yes/yellow/purple.
        #expect(DoorState.yes.isTraversible)
        #expect(DoorState.yellow.isTraversible)
        #expect(DoorState.purple.isTraversible)
        #expect(!DoorState.unknown.isTraversible)
        #expect(!DoorState.no.isTraversible)
    }

    // MARK: DungeonRoom

    @Test("DungeonRoom: default, isEmpty, isDefault")
    func room() {
        let d = DungeonRoom()
        #expect(d.isDefault)
        #expect(d.isEmpty)                                   // unmarked
        #expect(DungeonRoom(roomType: .offTheMap).isEmpty)   // off-map counts as empty
        #expect(!DungeonRoom(roomType: .nonDescript).isEmpty)
        // A brightness-toggled-off blank room is NOT default (serializes fully).
        #expect(!DungeonRoom(floorDropAppearsBright: false).isDefault)
        #expect(!DungeonRoom(isCompleted: true).isDefault)
    }

    // MARK: DungeonRoomMap

    @MainActor
    @Test("room get/set; doors; circle; old-man count")
    func map() {
        let m = DungeonRoomMap()
        #expect(m.room(col: 3, row: 4).isDefault)
        #expect(m.setRoom(DungeonRoom(roomType: .oldManHint), col: 3, row: 4))
        #expect(m.room(col: 3, row: 4).roomType == .oldManHint)
        #expect(m.oldManCount == 1)
        m.setRoom(DungeonRoom(roomType: .bombUpgrade), col: 0, row: 0)
        #expect(m.oldManCount == 2)

        // Doors.
        m.setHorizontalDoor(.yes, col: 6, row: 7)
        #expect(m.horizontalDoor(col: 6, row: 7) == .yes)
        m.setVerticalDoor(.no, col: 7, row: 6)
        #expect(m.verticalDoor(col: 7, row: 6) == .no)

        // Circle.
        #expect(!m.isCircled(col: 1, row: 1))
        m.toggleCircle(col: 1, row: 1)
        #expect(m.isCircled(col: 1, row: 1))
    }

    @MainActor
    @Test("transport pairs: two allowed, a third rejected; counts track")
    func transportLegality() {
        let m = DungeonRoomMap()
        #expect(m.setRoom(DungeonRoom(roomType: .transport3), col: 0, row: 0))
        #expect(m.transportCount(3) == 1)
        #expect(m.setRoom(DungeonRoom(roomType: .transport3), col: 1, row: 0))
        #expect(m.transportCount(3) == 2)
        // Third copy rejected; the target cell is unchanged.
        #expect(!m.canPlaceTransport(3, col: 2, row: 0))
        #expect(!m.setRoom(DungeonRoom(roomType: .transport3), col: 2, row: 0))
        #expect(m.room(col: 2, row: 0).isDefault)
        #expect(m.transportCount(3) == 2)
        // Re-marking an existing transport-3 cell as transport-3 is fine.
        #expect(m.canPlaceTransport(3, col: 0, row: 0))
        // Changing one away frees a slot.
        m.setRoom(DungeonRoom(roomType: .nonDescript), col: 0, row: 0)
        #expect(m.transportCount(3) == 1)
        #expect(m.canPlaceTransport(3, col: 2, row: 0))
    }

    @MainActor
    @Test("model has 9 room maps that survive a groundhog reset")
    func modelRoomMaps() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        #expect(model.dungeonRoomMaps.count == 9)
        model.dungeonRoomMaps[0].setRoom(DungeonRoom(roomType: .startEnterFromS), col: 3, row: 7)
        model.resetForGroundhogOrRouters()
        #expect(model.dungeonRoomMaps[0].room(col: 3, row: 7).roomType == .startEnterFromS)
    }
}
