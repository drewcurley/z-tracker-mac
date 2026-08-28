import Testing
import TrackerCore
@testable import ZTrackerMac

/// The overworld-only enemies (T-185) render from game-sprite GIFs, not the dungeon
/// sheet — so their filenames must actually resolve, or the picker shows blanks.
@MainActor
struct OverworldEnemyGlyphTests {
    @Test("octorok / peahat / leever game sprites load")
    func spritesLoad() {
        for e in [MonsterDetail.octorok, .peahat, .leever] {
            let name = OverworldEnemyGlyph.gifName(e)
            #expect(!name.isEmpty)
            #expect(GameSprite.image(name) != nil, "missing game sprite '\(name)' for \(e)")
        }
    }

    @Test("bomb-droppers renders the plain bomb sprite (T-217)")
    func bombDroppersSprite() {
        // The generic marker resolves to the same bomb sprite the shops use — a plain bomb,
        // not a specific enemy — and it isn't on the dungeon sheet.
        #expect(OverworldEnemyGlyph.gifName(.bombDroppers) == "Bomb")
        #expect(GameSprite.image("Bomb") != nil)
        #expect(DungeonMonsterAtlas.sprite(.bombDroppers) == nil)
    }
}
