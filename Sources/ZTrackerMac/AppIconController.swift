import AppKit

/// The **simple** icon is the app's default bundle icon (T-178), so it shows reliably
/// whether the app is open or closed. This just handles the optional override for
/// people who prefer the original **detailed** design: while the app runs, it swaps
/// the dock icon to `AppIcon-detailed.png`. That override is running-app only — when
/// the app is closed the Dock always shows the bundle's default (simple) — which
/// deliberately avoids the writable-location fragility of a persistent custom icon.
/// No-op when unbundled (no resource).
@MainActor
enum AppIconController {
    static func apply(useDetailed: Bool) {
        guard useDetailed,
              let url = Bundle.main.resourceURL?.appendingPathComponent("AppIcon-detailed.png"),
              let image = NSImage(contentsOf: url) else {
            NSApp.applicationIconImage = nil    // bundle icns = the default simple icon
            return
        }
        NSApp.applicationIconImage = image
    }
}
