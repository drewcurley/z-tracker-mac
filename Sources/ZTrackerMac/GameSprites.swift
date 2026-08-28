import SwiftUI
import ImageIO
import CoreGraphics
import TrackerCore

/// Loads the higher-fidelity game item sprites (the GIFs in Resources) as CGImages —
/// one first-frame per name, cached — for the item tracker and dungeon item boxes
/// (T-161). These sprites already carry alpha, so they render straight with
/// nearest-neighbor; they replace the tracker's cramped `icons7x7` crops. Any icon
/// without a mapped sprite falls back to the original atlas sprite via `ItemGlyph`.
@MainActor
enum GameSprite {
    private static var cache: [String: CGImage?] = [:]

    /// The first frame of the named GIF as a CGImage (nil if missing), memoized.
    static func image(_ name: String) -> CGImage? {
        if let hit = cache[name] { return hit }
        let img: CGImage? = {
            guard let url = AppResources.url(forResource: name, withExtension: "gif"),
                  let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
            return cg
        }()
        cache[name] = img
        return img
    }

    /// The GIF (filename without extension) that renders an item-tracker icon, or nil
    /// to fall back to the original atlas sprite. Names match the supplied files.
    static func itemFile(_ icon: ItemIconAtlas.Icon) -> String? {
        switch icon {
        case .brownSword:     "Wooden Sword (Up)"
        case .whiteSword:     "White Sword (Up)"
        case .magicalSword:   "Magical Sword (Menu)"
        case .heartContainer: "Heart Container"
        case .key:            "Magical Key"
        case .boomerang:      "Boomerang"
        case .magicBoomerang: "Magical Boomerang"
        case .bow:            "Bow"
        case .bowAndArrow:    "Bow"
        case .woodArrow:      "Arrow (Up)"
        case .silverArrow:    "Silver Arrow (Up)"
        case .raft:           "Raft2"
        case .ladder:         "Stepladder"
        case .recorder:       "Recorder"
        case .wand:           "Magical Rod"
        case .redCandle:      "Red Candle"
        case .blueCandle:     "Blue Candle"
        case .redRing:        "Red Ring"
        case .blueRing:       "Blue Ring"
        case .powerBracelet:  "Power Bracelet"
        case .book:           "Book of Magic"
        case .boomBook:       "Book of Magic"
        case .magicShield:    "Magical Shield"
        case .bait:           "Food"
        case .rupee:          "Rupy"
        case .bomb:           "Bomb"
        case .owKeyArmos:     "Armos Knight - Statue"
        case .zelda:          "Princess Zelda"
        case .ganon:          "7 - Ganon - Blue1"
        // No dedicated game sprite — keep the original atlas glyph.
        case .questionMarks, .basementStair, .wsMsBombUpgrade: nil
        }
    }

    /// The game sprite for an overworld interior mark, keyed by its `ow_icons5x9`
    /// index (see `OverworldTileMark.iconSource`). Tracker-only concepts with no game
    /// sprite — the money secrets, money-making game, door repair — return nil and keep
    /// the original atlas glyph.
    static func overworldFile(index: Int) -> String? {
        switch index {
        case 3:  "Old Man"               // hint shop / old-man cave
        case 4:  "Heart Container"       // take-any (match the item heart)
        case 5:  "Life Potion"           // potion shop
        case 7:  "Armos Knight - Statue" // armos
        case 10: "Rupy"                  // money game — static orange rupee (frame 0)
        case 11: "Goriya (Front)"        // unknown secret — the secret-giver
        case 12: "Fire"                  // door repair (a joke, per request)
        case 13: "Letter"                // the letter
        default: nil                     // the sized secrets (6/8/9) are composites
        }
    }

    /// The game sprite for an overworld shop's item (icons3x7).
    static func shopFile(_ kind: ShopKind) -> String? {
        switch kind {
        case .arrow:   "Arrow (Up)"
        case .bomb:    "Bomb"
        case .book:    "Book of Magic"
        case .candle:  "Blue Candle"
        case .blueRing: "Blue Ring"
        case .meat:    "Food"
        case .key:     "Key"
        case .shield:  "Magical Shield"
        }
    }
}

/// One tracker item icon: the real game sprite (T-161) when one is mapped for `icon`,
/// otherwise the original pixel-art atlas sprite (unchanged). Both render
/// nearest-neighbor and preserve their native aspect ratio inside the caller's frame,
/// so tall sprites (swords) aren't stretched. Callers apply `.frame`/`.opacity` exactly
/// as they did to the old `Image(atlasIcon:)`.
struct ItemGlyph: View {
    let icon: ItemIconAtlas.Icon
    init(_ icon: ItemIconAtlas.Icon) { self.icon = icon }
    var body: some View {
        if icon == .wsMsBombUpgrade {
            // The bomb-upgrade "bomb+" — composed from the real bomb sprite plus a "+" badge,
            // replacing the low-fidelity atlas glyph (T-218).
            BombUpgradeGlyph()
        } else if let file = GameSprite.itemFile(icon), let cg = GameSprite.image(file) {
            Image(decorative: cg, scale: 1, orientation: .up)
                .resizable().interpolation(.none).aspectRatio(contentMode: .fit)
        } else if let img = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
            img.interpolation(.none).resizable()
        } else {
            Color.clear
        }
    }
}

/// The bomb-upgrade icon (T-218): the real bomb game sprite with a small green "+" in the upper-right
/// (outlined for contrast on any background), signifying "more bombs". Scales to the caller's frame.
/// Used for both swordless upgrades and the Shop & Price window's bomb-upgrade row.
struct BombUpgradeGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topTrailing) {
                if let cg = GameSprite.image("Bomb") {
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .resizable().interpolation(.none).aspectRatio(contentMode: .fit)
                        // Leave room in the top-right for the badge.
                        .padding(.top, side * 0.14).padding(.trailing, side * 0.14)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
                }
                Image(systemName: "plus")
                    .font(.system(size: side * 0.5, weight: .black))
                    .foregroundStyle(Color(red: 0.30, green: 0.92, blue: 0.36))
                    // A dark outline so the badge reads on light or dark art.
                    .shadow(color: .black, radius: 0.5).shadow(color: .black, radius: 0.5)
                    .shadow(color: .black, radius: 0.5)
            }
        }
    }
}
