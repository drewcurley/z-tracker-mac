import AppKit

/// Swaps the dock icon at runtime between the bundle's original `.icns` and the
/// alternate **simple** icon (T-178). macOS shows `applicationIconImage` exactly as
/// given (no auto-rounding), and the supplied `simple.png` is a full square, so we
/// render it into the standard macOS icon shape — a rounded panel inset with the
/// conventional padding on a transparent field — to match other dock icons and the
/// original. Setting the image to `nil` reverts to the bundled `.icns` (original).
/// No-op when unbundled (no resource).
@MainActor
enum AppIconController {
    static func apply(useSimple: Bool) {
        guard useSimple else {
            NSApp.applicationIconImage = nil    // revert to the bundle icns (original)
            return
        }
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("AppIcon-simple.png"),
              let raw = NSImage(contentsOf: url) else { return }
        NSApp.applicationIconImage = macOSStyled(raw)
    }

    /// Draw `image` as a standard macOS app icon: the artwork scaled into a rounded
    /// panel inset by the conventional padding, on a transparent square. Proportions
    /// follow Apple's icon grid (≈824/1024 body, ≈185/1024 corner radius).
    private static func macOSStyled(_ image: NSImage) -> NSImage {
        let canvas: CGFloat = 1024
        let inset: CGFloat = 100                                   // ~10% padding each side
        let panel = NSRect(x: inset, y: inset, width: canvas - 2 * inset, height: canvas - 2 * inset)
        let radius = 185.0 * (panel.width / 824.0)                 // Apple's radius, scaled to the body
        let result = NSImage(size: NSSize(width: canvas, height: canvas))
        result.lockFocus()
        NSBezierPath(roundedRect: panel, xRadius: radius, yRadius: radius).addClip()
        image.draw(in: panel, from: .zero, operation: .sourceOver, fraction: 1)
        result.unlockFocus()
        return result
    }
}
