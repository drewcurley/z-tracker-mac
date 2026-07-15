import CoreGraphics
import Foundation
import TrackerCore

/// Composites the reference's faux items+hearts HUD (T-035.10), ported from
/// `Popouts.makeFauxItemsAndHeartsHUD` (`Z1R_WPF/Popouts.fs:47-108`). It mimics
/// the in-game inventory subscreen so players read it by muscle memory: the
/// "best" (all-items) bitmap with each slot **erased** when unowned or overlaid
/// with a "worse" (downgraded) variant at level 1, plus a max-hearts row.
///
/// Built by *drawing* into a CGContext (not raw pixel copies), so CoreGraphics
/// handles image orientation — no manual buffer flipping.
///
/// Two deliberate deviations from the reference (user request):
/// - **Hearts** fill logically — the first three are always red in the top row,
///   then fill the top row and spill into the second (the reference inverts the
///   rows so the extra hearts sit above the starting three).
/// - The **letter/potion** slot always shows the *letter* (lit from
///   `havePotionLetter`), since this port doesn't track holding a potion.
enum FauxItemsHUD {
    static let width = 98
    static let itemsHeight = 61
    /// 61 item rows + a 2-px gap + two 8-px heart rows.
    static let height = 79

    private static func load(_ name: String) -> CGImage? {
        guard
            let url = Bundle.module.url(forResource: name, withExtension: "png"),
            let provider = CGDataProvider(url: url as CFURL)
        else { return nil }
        return CGImage(pngDataProviderSource: provider, decode: nil,
                       shouldInterpolate: false, intent: .defaultIntent)
    }

    static func render(
        state s: PlayerComputedStateSummary,
        progress p: PlayerProgressAndTakeAnyHearts,
        havePotionLetter: Bool,
        haveBook: Bool
    ) -> CGImage? {
        guard
            let best = load("all-items-hud-pixels1"),
            let worse = load("all-items-hud-pixels1-worse"),
            let heartsImage = load("icons8x8"),
            let ctx = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.interpolationQuality = .none

        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        ctx.setFillColor(black)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Reference coordinates are top-left; the context is bottom-left, so
        // convert once here. (No context flip — that would draw images upside
        // down; drawing right-side-up at converted rects is the reliable path.)
        func rect(_ x1: Int, _ y1: Int, _ w: Int, _ h: Int) -> CGRect {
            CGRect(x: x1, y: height - y1 - h, width: w, height: h)
        }

        // The all-items bitmap fills the item region (top 61 rows).
        ctx.draw(best, in: rect(0, 0, width, itemsHeight))

        // Black out an unowned slot (reference `maybeErase`).
        func erase(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int, when cond: Bool) {
            guard cond else { return }
            ctx.setFillColor(black)
            ctx.fill(rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1))
        }
        // Overlay the downgraded "worse" variant (reference `copyWorse`).
        func overlayWorse(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int, when cond: Bool) {
            guard cond, let crop = worse.cropping(to: CGRect(x: x1, y: y1, width: x2 - x1 + 1, height: y2 - y1 + 1))
            else { return }
            ctx.draw(crop, in: rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1))
        }

        // Top row: raft, book, ring, ladder, key, bracelet.
        erase(6, 19, 0, 15, when: !s.haveRaft)
        erase(29, 36, 0, 15, when: !haveBook)
        erase(42, 48, 3, 11, when: s.ringLevel == 0); overlayWorse(42, 48, 3, 11, when: s.ringLevel == 1)
        erase(53, 68, 0, 15, when: !s.haveLadder)
        erase(73, 81, 0, 15, when: !s.haveAnyKey)
        erase(85, 92, 0, 15, when: !s.havePowerBracelet)
        // Middle row: boomerang, bombs, arrow, bow, candle.
        erase(10, 14, 28, 35, when: s.boomerangLevel == 0); overlayWorse(10, 14, 28, 35, when: s.boomerangLevel == 1)
        erase(33, 40, 24, 39, when: !p.hasBombs)
        erase(55, 59, 24, 39, when: s.arrowLevel == 0); overlayWorse(55, 59, 24, 39, when: s.arrowLevel == 1)
        erase(61, 69, 24, 39, when: !s.haveBow)
        erase(81, 88, 24, 39, when: s.candleLevel == 0); overlayWorse(81, 88, 24, 39, when: s.candleLevel == 1)
        // Bottom row: recorder, meat, letter (always the letter), wand.
        erase(12, 14, 40, 55, when: !s.haveRecorder)
        erase(33, 40, 40, 55, when: !p.hasMeat)
        overlayWorse(57, 64, 40, 55, when: true)               // the letter graphic lives in "worse"
        erase(57, 64, 40, 55, when: !havePotionLetter)
        erase(83, 86, 40, 55, when: !s.haveWand)

        // Hearts: first three red, fill the top row (y 63) then the second (y 71).
        let filled = heartsImage.cropping(to: CGRect(x: 0, y: 0, width: 8, height: 8))
        let empty = heartsImage.cropping(to: CGRect(x: 8, y: 0, width: 8, height: 8))
        let total = min(max(s.playerHearts, 0), 16)
        for n in 0..<total {
            let hx = 12 + (n % 8) * 8
            let hy = 63 + (n / 8) * 8
            if let heart = n < 3 ? filled : empty {
                ctx.draw(heart, in: rect(hx, hy, 8, 8))
            }
        }

        return ctx.makeImage()
    }
}
