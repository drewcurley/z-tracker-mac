import AppKit

/// Swaps the dock icon at runtime between the bundle's original `.icns` and the
/// alternate **simple** icon (T-178). `AppIcon-simple.png` is pre-rounded into the
/// standard macOS icon shape at build time (`scripts/make-simple-icon.swift`), so this
/// just loads and sets it — no per-launch rounding. Setting the image to `nil` reverts
/// to the bundled `.icns` (the original). No-op when unbundled (no resource).
@MainActor
enum AppIconController {
    static func apply(useSimple: Bool) {
        guard useSimple else {
            NSApp.applicationIconImage = nil    // revert to the bundle icns (original)
            return
        }
        if let url = Bundle.main.resourceURL?.appendingPathComponent("AppIcon-simple.png"),
           let image = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = image
        }
    }
}
