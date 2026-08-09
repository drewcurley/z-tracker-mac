import CoreGraphics
import TrackerCore

/// The dungeon floor-drop sprites (T-019.7, "D2b"), from the reference's
/// `zelda_items16x16.png` (`Graphics.fs:575`): a horizontal strip of 16×16 tiles
/// with **black as the transparency key**. The `FloorDropDetail → tile index` map
/// mirrors the reference `FloorDropDetail.Bmp()` (`DungeonRoomState.fs:198-206`)
/// against that sheet's tuple order — non-sequential (e.g. BombPack uses the
/// alternate-bomb tile 8).
enum DungeonFloorDropAtlas {
    static let tile = 16
    // threshold strips the near-black tile background these drops carry (T-188), so the
    // row-locator's rupee/key/bomb read cleanly on a light background. Over-stripping on
    // the dark room cells / picker boxes is invisible there.
    private static let sheet: CGImage? = AtlasLoader.load("zelda_items16x16", blackIsTransparent: true, threshold: 24)

    static func sprite(_ fd: FloorDropDetail) -> CGImage? {
        guard let sheet, let idx = tileIndex(fd) else { return nil }
        return sheet.cropping(to: CGRect(x: idx * tile, y: 0, width: tile, height: tile))
    }

    private static func tileIndex(_ fd: FloorDropDetail) -> Int? {
        switch fd {
        case .unmarked: nil
        case .triforce: 0
        case .heart: 1
        case .key: 3
        case .fiveRupee: 4
        case .map: 5
        case .compass: 6
        case .otherKeyItem: 7
        case .bombPack: 8       // alternate-bomb tile
        }
    }
}
