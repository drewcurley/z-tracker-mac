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
}
