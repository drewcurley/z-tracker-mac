import Testing
import TrackerCore
@testable import ZTrackerMac

/// T-019.7 — the monster and floor-drop sheets load and every marked detail
/// crops to a sprite (guards against a wrong resource name or an out-of-bounds
/// tile index). `unmarked` maps to no sprite by design.
@Suite("Dungeon detail atlases (T-019.7)")
struct DungeonDetailAtlasTests {
    @Test("every monster (except Unmarked) resolves to a sprite")
    func monstersLoad() {
        for md in MonsterDetail.allCases {
            if md == .unmarked {
                #expect(DungeonMonsterAtlas.sprite(md) == nil)
            } else {
                #expect(DungeonMonsterAtlas.sprite(md) != nil, "no sprite for \(md)")
            }
        }
    }

    @Test("every floor drop (except Unmarked) resolves to a sprite")
    func floorDropsLoad() {
        for fd in FloorDropDetail.allCases {
            if fd == .unmarked {
                #expect(DungeonFloorDropAtlas.sprite(fd) == nil)
            } else {
                #expect(DungeonFloorDropAtlas.sprite(fd) != nil, "no sprite for \(fd)")
            }
        }
    }
}
