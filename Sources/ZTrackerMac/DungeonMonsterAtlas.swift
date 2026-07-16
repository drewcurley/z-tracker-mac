import CoreGraphics
import TrackerCore

/// The dungeon monster-detail sprites (T-019.7, "D2b"), from the reference's
/// `zelda_bosses16x16.png` (`Graphics.fs:552-554`): a horizontal strip of 16×16
/// tiles with **black as the transparency key**. The `MonsterDetail → tile index`
/// map mirrors the reference tuple binding order — note index 11 is `old_man`
/// (not a `MonsterDetail`), so the map is deliberately non-sequential.
enum DungeonMonsterAtlas {
    static let tile = 16
    private static let sheet: CGImage? = AtlasLoader.load("zelda_bosses16x16", blackIsTransparent: true)

    static func sprite(_ md: MonsterDetail) -> CGImage? {
        guard let sheet, let idx = tileIndex(md) else { return nil }
        return sheet.cropping(to: CGRect(x: idx * tile, y: 0, width: tile, height: tile))
    }

    /// The "old man" NPC sprite (sheet index 11) — not a `MonsterDetail`, but the
    /// reference uses it for the old-man-count icon (`Graphics.old_man_bmp`).
    static var oldMan: CGImage? {
        sheet?.cropping(to: CGRect(x: 11 * tile, y: 0, width: tile, height: tile))
    }

    private static func tileIndex(_ md: MonsterDetail) -> Int? {
        switch md {
        case .unmarked: nil
        case .digdogger: 0
        case .gleeok: 1
        case .bow: 2            // Gohma
        case .manhandla: 3
        case .blueWizzrobe: 4
        case .patra: 5
        case .dodongo: 6
        case .redBubble: 7
        case .blueBubble: 8
        case .blueDarknut: 9
        case .other: 10
        // 11 = old_man (not a MonsterDetail)
        case .vire: 12
        case .zol: 13
        case .polsVoice: 14
        case .redTektite: 15
        case .redGoriya: 16
        case .rope: 17
        case .stalfos: 18
        case .wallmaster: 19
        case .gel: 20
        case .keese: 21
        case .likelike: 22
        case .gibdo: 23
        case .redLynel: 24
        case .blueMoblin: 25
        case .aquamentus: 26
        case .blueLanmola: 27
        case .moldorm: 28
        case .rupeeBoss: 29
        case .traps: 30
        case .other2: 31
        }
    }
}
