import CoreGraphics
import SwiftUI
import TrackerCore

/// Loads the reference app's item-icon strip (`icons7x7.png`, 224×7px = 32
/// icons of 7×7px each) and crops individual icons on demand — the sprites
/// used for the dungeon item boxes and the item-progress grid. The 32-icon
/// order is transcribed exactly from `Graphics.fs:530-548`'s `icons7x7.png`
/// destructuring (`boomerang` … `ws_ms_bomb_upgrade`); the reference treats
/// pure black as transparent, matched here via a decode array.
/// Seed-option flags that change how certain item slots display.
struct ItemIconOptions: Equatable {
    /// Swordless: the white-sword item shows as a bomb upgrade.
    var wsmsReplacedByBU = false
    /// Item slot 0 is the Book (true, default) or the Magic Shield (false).
    var isCurrentlyBook = true
}

extension TrackerModel {
    /// The seed-option flags that affect item-icon display, bundled for the
    /// item boxes/picker.
    var iconOptions: ItemIconOptions {
        ItemIconOptions(wsmsReplacedByBU: isWSMSReplacedByBU, isCurrentlyBook: isCurrentlyBook)
    }
}

enum ItemIconAtlas {
    static let iconWidth = 7
    static let iconHeight = 7
    static let iconCount = 32

    /// Named indices into `icons7x7.png`, in the reference's slice order.
    enum Icon: Int {
        case boomerang = 0, bow, magicBoomerang, raft, ladder, recorder, wand, redCandle
        case book, key, silverArrow, woodArrow, redRing, magicShield, boomBook, heartContainer
        case powerBracelet, whiteSword, owKeyArmos, brownSword, magicalSword, blueCandle, blueRing, ganon
        case zelda, bomb, bowAndArrow, bait, questionMarks, rupee, basementStair, wsMsBombUpgrade
    }

    /// The `icons7x7` icon for an `ITEMS` index (`Box.cellCurrent`, `0…14`).
    /// Mirrors the reference's `allItemBMPsWithHeartShuffle` mapping
    /// (`Graphics.fs:778-779`) — `ITEMS` order → item bmp.
    static func icon(forItemIndex itemIndex: Int) -> Icon? {
        switch itemIndex {
        case ITEMS.bookOrShield: .book
        case ITEMS.boomerang: .boomerang
        case ITEMS.bow: .bow
        case ITEMS.powerBracelet: .powerBracelet
        case ITEMS.ladder: .ladder
        case ITEMS.magicBoomerang: .magicBoomerang
        case ITEMS.anyKey: .key
        case ITEMS.raft: .raft
        case ITEMS.recorder: .recorder
        case ITEMS.redCandle: .redCandle
        case ITEMS.redRing: .redRing
        case ITEMS.silverArrow: .silverArrow
        case ITEMS.wand: .wand
        case ITEMS.whiteSword: .whiteSword
        case ITEMS.heartContainer: .heartContainer
        default: nil
        }
    }

    /// The icon for an `ITEMS` index, honoring the seed-option item swaps that
    /// change how a slot displays (`CustomComboBoxes.fs:46,48`):
    /// - swordless (`wsmsReplacedByBU`): the white-sword *item* (index 13, the
    ///   shuffled white-sword weapon) renders as the bomb-upgrade sprite.
    /// - book/shield (`isCurrentlyBook`): slot 0 renders as the book or the
    ///   magic shield.
    /// Every other item — including the wood sword — is unchanged.
    static func icon(forItemIndex itemIndex: Int, options: ItemIconOptions) -> Icon? {
        if options.wsmsReplacedByBU && itemIndex == ITEMS.whiteSword { return .wsMsBombUpgrade }
        if itemIndex == ITEMS.bookOrShield { return options.isCurrentlyBook ? .book : .magicShield }
        return icon(forItemIndex: itemIndex)
    }

    private static let fullImage: CGImage? = AtlasLoader.load("icons7x7", blackIsTransparent: true)

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage, (0..<iconCount).contains(index) else { return nil }
        return fullImage.cropping(to: CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight))
    }

    static func cgImage(_ icon: Icon) -> CGImage? { self.icon(at: icon.rawValue) }
}

/// Loads the reference app's dungeon-cell icon strip (`zelda_items16x16.png`,
/// 208×16px = 13 icons of 16×16px each) and crops icons on demand. The 13-icon
/// order is transcribed from `Graphics.fs:575-590` (`zi_triforce` …
/// `zi_staircase`). `staircase` is the basement-stair glyph that renders
/// `DungeonTrackerInstance.currentlyHasBasementStair` (T-016.2).
enum DungeonCellIconAtlas {
    static let iconWidth = 16
    static let iconHeight = 16
    static let iconCount = 13

    enum Icon: Int {
        case triforce = 0, heart, bomb, key, fiver, map, compass, otherItem
        case altBomb, rock, tree, atlas, staircase
    }

    private static let fullImage: CGImage? = AtlasLoader.load("zelda_items16x16", blackIsTransparent: true)

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage, (0..<iconCount).contains(index) else { return nil }
        return fullImage.cropping(to: CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight))
    }

    static func cgImage(_ icon: Icon) -> CGImage? { self.icon(at: icon.rawValue) }
}

/// Shared PNG-atlas loader. Optionally maps pure black to transparent (the
/// reference's sprite-sheet background convention) via a CGImage decode array.
enum AtlasLoader {
    static func load(_ resource: String, blackIsTransparent: Bool) -> CGImage? {
        guard
            let url = Bundle.module.url(forResource: resource, withExtension: "png"),
            let provider = CGDataProvider(url: url as CFURL),
            let image = CGImage(pngDataProviderSource: provider, decode: nil,
                                shouldInterpolate: false, intent: .defaultIntent)
        else { return nil }
        guard blackIsTransparent else { return image }
        // Mask out pure black (RGB 0,0,0) so the sprite background is transparent.
        return image.copy(maskingColorComponents: [0, 0, 0, 0, 0, 0]) ?? image
    }
}

extension Image {
    /// A pixel-art SwiftUI `Image` from an atlas crop (nearest-neighbor).
    init?(atlasIcon cgImage: CGImage?) {
        guard let cgImage else { return nil }
        self.init(decorative: cgImage, scale: 1, orientation: .up)
    }
}
