import Testing
@testable import TrackerCore

@Suite("Dungeon room two-monster support (T-116)")
struct DungeonRoomTwoMonstersTests {
    @Test("toggleMonster fills primary then secondary, up to two")
    func fillsTwoSlots() {
        var r = DungeonRoom()
        #expect(r.monsters.isEmpty)
        r.toggleMonster(.gleeok)
        #expect(r.monsterDetail == .gleeok && r.monsterDetail2 == .unmarked)
        #expect(r.monsters == [.gleeok])
        r.toggleMonster(.rope)
        #expect(r.monsterDetail == .gleeok && r.monsterDetail2 == .rope)
        #expect(r.monsters == [.gleeok, .rope])
    }

    @Test("tapping a present monster removes it; secondary promotes to primary")
    func removeAndPromote() {
        var r = DungeonRoom(monsterDetail: .gleeok, monsterDetail2: .rope)
        r.toggleMonster(.gleeok)                 // remove primary
        #expect(r.monsterDetail == .rope && r.monsterDetail2 == .unmarked)
        // Now remove the (promoted) primary.
        r.toggleMonster(.rope)
        #expect(r.monsters.isEmpty)
    }

    @Test("removing the secondary leaves the primary")
    func removeSecondary() {
        var r = DungeonRoom(monsterDetail: .gleeok, monsterDetail2: .rope)
        r.toggleMonster(.rope)
        #expect(r.monsterDetail == .gleeok && r.monsterDetail2 == .unmarked)
    }

    @Test("with both slots full, a new monster replaces the secondary")
    func replacesSecondaryWhenFull() {
        var r = DungeonRoom(monsterDetail: .gleeok, monsterDetail2: .rope)
        r.toggleMonster(.stalfos)
        #expect(r.monsterDetail == .gleeok && r.monsterDetail2 == .stalfos)
    }

    @Test("tapping unmarked clears both; isDefault accounts for the 2nd monster")
    func clearBoth() {
        var r = DungeonRoom(monsterDetail: .gleeok, monsterDetail2: .rope)
        #expect(!r.isDefault)
        r.toggleMonster(.unmarked)
        #expect(r.monsters.isEmpty)
        #expect(r.isDefault)
        // A room with only a secondary-slot marking is likewise non-default.
        #expect(!DungeonRoom(monsterDetail2: .rope).isDefault)
    }
}
