import SwiftUI
import CoreGraphics
import TrackerCore

/// The overworld hover magnifier (T-254) — the reference's `MakeMagnifier`
/// (`Z1R_WPF/UIComponents.fs:19-179`): the 3×3 screens around the hovered one, redrawn from the
/// map's own block data at 8× (each 16×11 screen → 128×88), with a darkened block grid, the
/// diagonal rocks split along their diagonals, and every entrance ringed so it "pops".
enum OverworldMagnifierAtlas {
    static let enlarge = 8
    /// Width of an entrance's colored ring (`POP`).
    static let pop = 1
    static let width = 16 * enlarge
    static let height = 11 * enlarge

    private struct RGB: Equatable { var r, g, b: UInt8 }

    /// One screen's 16×11 block colors (one pixel per block in the strip PNG).
    private struct Blocks {
        let pixels: [RGB]
        func at(_ x: Int, _ y: Int) -> RGB {
            pixels[min(max(y, 0), 10) * 16 + min(max(x, 0), 15)]
        }
    }

    @MainActor private static var cache: [Int: CGImage] = [:]

    /// The magnified screen, built once per quest + screen and cached.
    @MainActor static func image(quest: OverworldQuest, column: Int, row: Int) -> CGImage? {
        let key = quest.referenceAppIndex * 128 + row * 16 + column
        if let hit = cache[key] { return hit }
        guard let image = render(quest: quest, column: column, row: row) else { return nil }
        cache[key] = image
        return image
    }

    private static func blocks(quest: OverworldQuest, column: Int, row: Int) -> Blocks? {
        guard let tile = OverworldBackgroundAtlas.tile(quest: quest, column: column, row: row) else { return nil }
        var raw = [UInt8](repeating: 0, count: 16 * 11 * 4)
        let drawn = raw.withUnsafeMutableBytes { buf -> Bool in
            guard let ctx = CGContext(data: buf.baseAddress, width: 16, height: 11, bitsPerComponent: 8,
                                      bytesPerRow: 16 * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return false }
            ctx.interpolationQuality = .none
            ctx.draw(tile, in: CGRect(x: 0, y: 0, width: 16, height: 11))
            return true
        }
        guard drawn else { return nil }
        // A bitmap context's first row in memory is the image's top row, so y=0 is the top.
        var pixels: [RGB] = []
        pixels.reserveCapacity(16 * 11)
        for y in 0..<11 {
            for x in 0..<16 {
                let i = (y * 16 + x) * 4
                pixels.append(RGB(r: raw[i], g: raw[i + 1], b: raw[i + 2]))
            }
        }
        return Blocks(pixels: pixels)
    }

    /// The screen whose diagonal-rock data (and pixels) to use — the tables are first-quest
    /// based, so a few screens borrow from a lookalike (`UIComponents.fs:65-75`).
    static func rockSource(quest: OverworldQuest, column: Int, row: Int) -> (Int, Int) {
        let n = quest.referenceAppIndex
        if n == 1 && column == 4 && row == 7 { return (14, 5) }   // 2Q has a cave like 14,5 here
        if n == 1 && column == 11 && row == 0 { return (2, 4) }   // 2Q has a fairy here
        if n != 0 && column == 12 && row == 3 { return (2, 4) }   // non-1Q has a whistle lake here
        return (column, row)
    }

    private static func render(quest: OverworldQuest, column i: Int, row j: Int) -> CGImage? {
        guard let screen = blocks(quest: quest, column: i, row: j) else { return nil }
        let (bi, bj) = rockSource(quest: quest, column: i, row: j)
        let borrowed = (bi, bj) == (i, j) ? screen : (blocks(quest: quest, column: bi, row: bj) ?? screen)
        let e = enlarge
        var out = [RGB](repeating: RGB(r: 0, g: 0, b: 0), count: width * height)
        func set(_ px: Int, _ py: Int, _ c: RGB) { out[py * width + px] = c }

        for x in 0..<16 {
            for y in 0..<11 {
                let c = screen.at(x, y)
                for px in 0..<e {
                    for py in 0..<e {
                        var p = c
                        if OverworldDiagonalRocks.contains(.neUpper, tx: bi, ty: bj, x: x, y: y) {
                            if px + py > e - 1 { p = borrowed.at(x, y + 1) }
                        } else if OverworldDiagonalRocks.contains(.seUpper, tx: bi, ty: bj, x: x, y: y) {
                            if px < py { p = borrowed.at(x, y + 1) }
                        } else if OverworldDiagonalRocks.contains(.neLower, tx: bi, ty: bj, x: x, y: y) {
                            if px + py < e - 1 { p = borrowed.at(x, y - 1) }
                        } else if OverworldDiagonalRocks.contains(.seLower, tx: bi, ty: bj, x: x, y: y) {
                            if px > py { p = borrowed.at(x, y - 1) }
                        }
                        // Edges of each block, darkened to draw the grid.
                        if (px + 1) % e == 0 || (py + 1) % e == 0 {
                            p = RGB(r: p.r / 2, g: p.g / 2, b: p.b / 2)
                        }
                        set(x * e + px, y * e + py, p)
                    }
                }
            }
        }

        // Make the entrances pop: a thin black outline, a colored ring, then the block itself.
        // No entrance sits on a screen edge, so only interior blocks are checked.
        let black = RGB(r: 0, g: 0, b: 0)
        for x in 1...14 {
            for y in 1...9 {
                let c = screen.at(x, y)
                let ring: RGB?
                switch c {
                case black:
                    // Two black blocks side by side are vanilla's one two-wide entrance — ring one.
                    ring = screen.at(x - 1, y) == black ? nil : RGB(r: 0x00, g: 0xCC, b: 0xCC)
                case RGB(r: 0x00, g: 0xFF, b: 0xFF),   // cyan bomb spot
                     RGB(r: 0xFF, g: 0xFF, b: 0x00),   // yellow recorder spot
                     RGB(r: 0xFF, g: 0x00, b: 0x00),   // red burn spot
                     RGB(r: 0xFF, g: 0x00, b: 0xFF):   // magenta push spot
                    ring = black
                default:
                    ring = nil
                }
                guard let ring else { continue }
                for px in (x * e - pop - 1)...((x + 1) * e - 1 + pop + 1) {
                    for py in (y * e - pop - 1)...((y + 1) * e - 1 + pop + 1) { set(px, py, black) }
                }
                for px in (x * e - pop)...((x + 1) * e - 1 + pop) {
                    for py in (y * e - pop)...((y + 1) * e - 1 + pop) { set(px, py, ring) }
                }
                for px in (x * e)...((x + 1) * e - 1) {
                    for py in (y * e)...((y + 1) * e - 1) { set(px, py, c) }
                }
            }
        }

        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for (k, p) in out.enumerated() {
            bytes[k * 4] = p.r; bytes[k * 4 + 1] = p.g; bytes[k * 4 + 2] = p.b
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}

/// The magnifier panel (T-254): 3×3 magnified screens around the hovered one (clamped at the map
/// edge, so an edge screen isn't centered), a white frame behind the hovered screen, the Lost
/// Woods / Lost Hills direction arrows, and the legend. Non-interactive.
struct OverworldMagnifierView: View {
    let quest: OverworldQuest
    let column: Int
    let row: Int
    var mirrored: Bool = false

    private static let bt: CGFloat = 2
    private static let tileW = CGFloat(OverworldMagnifierAtlas.width)
    private static let tileH = CGFloat(OverworldMagnifierAtlas.height)
    static let contentWidth = 3 * tileW + 4 * bt
    static let contentHeight = 3 * tileH + 4 * bt
    private static let arrowColor = Color(red: 0, green: 180 / 255, blue: 250 / 255)

    var body: some View {
        let xmin = min(max(column - 1, 0), 13)
        let ymin = min(max(row - 1, 0), 5)
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Color.black
                Rectangle().fill(Color.white)
                    .frame(width: Self.tileW + 2 * Self.bt, height: Self.tileH + 2 * Self.bt)
                    .offset(x: CGFloat(column - xmin) * (Self.tileW + Self.bt),
                            y: CGFloat(row - ymin) * (Self.tileH + Self.bt))
                ForEach(0..<9, id: \.self) { k in
                    let x = k % 3, y = k / 3
                    let dx = Self.bt + CGFloat(x) * (Self.tileW + Self.bt)
                    let dy = Self.bt + CGFloat(y) * (Self.tileH + Self.bt)
                    screen(xmin + x, ymin + y)
                        .offset(x: dx, y: dy)
                    arrows(column: xmin + x, row: ymin + y, dx: dx, dy: dy)
                }
            }
            .frame(width: Self.contentWidth, height: Self.contentHeight, alignment: .topLeading)
            // The reference flips the magnifier with the map (`mirrorOverworldFEs`).
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            legend
        }
        .padding(5)
        .background(Color.gray)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder private func screen(_ c: Int, _ r: Int) -> some View {
        if let image = OverworldMagnifierAtlas.image(quest: quest, column: c, row: r) {
            Image(decorative: image, scale: 1, orientation: .up)
                .interpolation(.none)
                .frame(width: Self.tileW, height: Self.tileH)
        }
    }

    /// The reference's direction hints for the two maze screens (`UIComponents.fs:159-173`).
    @ViewBuilder private func arrows(column: Int, row: Int, dx: CGFloat, dy: CGFloat) -> some View {
        if column == 1 && row == 6 {          // Lost Woods
            arrow("\u{1F845}", dx + 3, dy - 2)
            arrow("\u{1F844}", dx + 3, dy + 18)
            arrow("\u{1F847}", dx + 3, dy + 38)
            arrow("\u{1F844}", dx + 3, dy + 58)
            arrow("\u{1F846}", dx + 101, dy + 28)
        } else if column == 11 && row == 1 {  // Lost Hills
            arrow("\u{1F845}", dx + 20, dy - 2)
            arrow("\u{1F845}", dx + 40, dy - 2)
            arrow("\u{1F845}", dx + 60, dy - 2)
            arrow("\u{1F845}", dx + 80, dy - 2)
            arrow("\u{1F844}", dx + 3, dy + 28)
        }
    }

    private func arrow(_ glyph: String, _ x: CGFloat, _ y: CGFloat) -> some View {
        Text(glyph)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Self.arrowColor)
            .frame(width: 22, height: 18)
            .background(Color.black.opacity(220 / 255))
            .offset(x: x, y: y + 6)
    }

    private var legend: some View {
        HStack(spacing: 4) {
            swatch(ring: .cyan, inner: .black); legendText("open cave")
            swatch(ring: .black, inner: .cyan); legendText("bomb spot")
            swatch(ring: .black, inner: .red); legendText("burn spot")
            swatch(ring: .black, inner: .yellow); legendText("recorder spot")
            swatch(ring: .black, inner: Color(red: 1, green: 0, blue: 1)); legendText("pushable spot")
        }
        .padding(.vertical, 2)
        .frame(width: Self.contentWidth)
        .background(Color(white: 30 / 255))
    }

    private func swatch(ring: Color, inner: Color) -> some View {
        let e = CGFloat(OverworldMagnifierAtlas.enlarge), p = CGFloat(OverworldMagnifierAtlas.pop)
        return Rectangle().fill(inner).frame(width: e, height: e)
            .padding(p).background(ring)
            .padding(1).background(Color.black)
    }

    private func legendText(_ s: String) -> some View {
        Text(s).font(.system(size: 11)).foregroundStyle(.orange)
    }
}

/// Reads only the hovered tile, so the panel re-renders on its own as the mouse crosses screens
/// (the same isolation as `OverworldHoverLayer`, T-244).
struct OverworldMagnifierOverlay: View {
    var hover: OverworldHoverState
    let quest: OverworldQuest
    var mirrored: Bool
    var enabled = true

    var body: some View {
        if enabled, let tile = hover.magnifierTile {
            OverworldMagnifierView(quest: quest, column: tile.x, row: tile.y, mirrored: mirrored)
        }
    }
}

extension View {
    /// Overlay `content` hanging just below this view's bottom edge, left-aligned, without
    /// affecting layout (T-254). The alignment guide must sit on an unconditional view: SwiftUI
    /// drops an explicit guide applied inside an `if` in the overlay builder, which pinned the
    /// magnifier to the map's bottom edge — over the map — instead of below it.
    func hangingBelow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        overlay(alignment: .bottomLeading) {
            ZStack(alignment: .topLeading) { content() }
                .alignmentGuide(.bottom) { $0[.top] }
        }
    }
}
