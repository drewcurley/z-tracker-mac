import Testing
import CoreGraphics
import TrackerCore
@testable import ZTrackerMac

/// T-254 — the hover magnifier's 8× screens (a port of the reference's `MakeMagnifier`).
@Suite("Overworld magnifier (T-254)")
@MainActor
struct OverworldMagnifierTests {
    private func rgb(_ image: CGImage, _ x: Int, _ y: Int) -> (UInt8, UInt8, UInt8) {
        var px = [UInt8](repeating: 0, count: 4)
        px.withUnsafeMutableBytes { buf in
            let ctx = CGContext(data: buf.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            ctx.interpolationQuality = .none
            // Draw so that pixel (x,y) (top-left origin) lands on the 1×1 context.
            ctx.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
        }
        return (px[0], px[1], px[2])
    }

    @Test("every screen of every quest renders at 8× (128×88)")
    func rendersAll() {
        for quest in OverworldQuest.allCases {
            for i in 0..<128 {
                let img = OverworldMagnifierAtlas.image(quest: quest, column: i % 16, row: i / 16)
                #expect(img?.width == 128 && img?.height == 88)
            }
        }
    }

    @Test("an open cave block gets the cyan ring; block edges are darkened")
    func cavePops() throws {
        // Find a first-quest screen with an interior black block whose left neighbor isn't black.
        let quest = OverworldQuest.first
        var found: (Int, Int, Int, Int)?
        search: for s in 0..<128 {
            guard let tile = OverworldBackgroundAtlas.tile(quest: quest, column: s % 16, row: s / 16) else { continue }
            for y in 1...9 { for x in 1...14
                where rgb(tile, x, y) == (0, 0, 0) && rgb(tile, x - 1, y) != (0, 0, 0) {
                found = (s % 16, s / 16, x, y); break search
            } }
        }
        let (c, r, x, y) = try #require(found)
        let img = try #require(OverworldMagnifierAtlas.image(quest: quest, column: c, row: r))
        let e = OverworldMagnifierAtlas.enlarge
        #expect(rgb(img, x * e - 1, y * e + 3) == (0x00, 0xCC, 0xCC))   // the ring
        #expect(rgb(img, x * e - 2, y * e + 3) == (0, 0, 0))            // its black outline
        #expect(rgb(img, x * e + 3, y * e + 3) == (0, 0, 0))            // the cave itself
    }

    @Test("the reference's diagonal-rock tables and per-quest borrowing are ported")
    func rocksAndBorrowing() {
        #expect(OverworldDiagonalRocks.contains(.seUpper, tx: 1, ty: 0, x: 2, y: 2))
        #expect(!OverworldDiagonalRocks.contains(.neUpper, tx: 1, ty: 0, x: 2, y: 2))
        #expect(OverworldMagnifierAtlas.rockSource(quest: .second, column: 4, row: 7) == (14, 5))
        #expect(OverworldMagnifierAtlas.rockSource(quest: .first, column: 4, row: 7) == (4, 7))
        #expect(OverworldMagnifierAtlas.rockSource(quest: .mixedFirst, column: 12, row: 3) == (2, 4))
        #expect(OverworldMagnifierAtlas.rockSource(quest: .first, column: 12, row: 3) == (12, 3))
    }
}
