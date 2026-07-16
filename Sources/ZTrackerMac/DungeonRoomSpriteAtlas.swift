import CoreGraphics
import TrackerCore

/// The dungeon room-type sprites (T-019.5), from the reference's
/// `new_icons13x9.png` (`Graphics.dungeonRoomBmpPairs`). The sheet is a strip of
/// 13×9 tiles; each column-tile holds two variants stacked vertically —
/// **uncompleted** on top (y 0…8), **completed** on the bottom (y 9…17). The
/// `RoomType → tile index` map is `DungeonRoomState.BmpPair` (`:366-405`).
enum DungeonRoomSpriteAtlas {
    static let tileW = 13
    static let tileH = 9

    /// Full room-tile art (black is real here — it's the room interior, not a
    /// transparency key), so no black-masking.
    private static let sheet: CGImage? = AtlasLoader.load("new_icons13x9", blackIsTransparent: false)

    /// The sprite for a room type in the given completion state. `unmarked` uses
    /// the index-0 empty-room sprite (as the reference's fast path draws), so the
    /// grid shows faint room outlines rather than blank cells.
    static func sprite(_ roomType: RoomType, completed: Bool) -> CGImage? {
        guard let sheet else { return nil }
        let idx = tileIndex(roomType)
        // Gannon/Zelda only have the "completed" (bottom) variant.
        let y = (completed || roomType == .gannon || roomType == .zelda) ? tileH : 0
        return sheet.cropping(to: CGRect(x: idx * tileW, y: y, width: tileW, height: tileH))
    }

    private static func tileIndex(_ r: RoomType) -> Int {
        switch r {
        case .unmarked: 0
        case .nonDescript: 1
        case .doubleMoat: 2
        case .chevy: 3
        case .rightMoat: 4
        case .topMoat: 5
        case .circleMoat: 6
        case .vChute: 7
        case .hChute: 8
        case .tee: 9
        case .maybePushBlock: 10
        case .itemBasement: 11
        case .oldManHint: 12
        case .hungryGoriyaMeatBlock: 13
        case .lifeOrMoney: 14
        case .bombUpgrade: 15
        case .turnstile: 16
        case .transport1: 17
        case .transport2: 18
        case .transport3: 19
        case .transport4: 20
        case .transport5: 21
        case .transport6: 22
        case .transport7: 23
        case .transport8: 24
        case .staircaseToUnknown: 25
        case .startEnterFromW: 26
        case .startEnterFromN: 27
        case .startEnterFromS: 28
        case .startEnterFromE: 29
        case .offTheMap: 30
        case .gannon: 31
        case .zelda: 32
        case .lavaMoat: 33
        }
    }
}
