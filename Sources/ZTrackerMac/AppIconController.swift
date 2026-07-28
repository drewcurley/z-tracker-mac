import AppKit

/// Swaps the dock icon between the bundle's original `.icns` and the alternate
/// **simple** icon (T-178), and makes the choice **persist even when the app is
/// closed** (T-179).
///
/// `NSApp.applicationIconImage` only changes the *running* app's dock icon — when it
/// quits, the Dock reverts to the bundle's `.icns`. So we also set a **Finder custom
/// icon** on the `.app` bundle (`NSWorkspace.setIcon`, the same mechanism as pasting an
/// icon in Get Info), which the Dock uses whether the app is open or not. Reverting
/// clears the custom icon, exposing the bundle's `.icns` (the original) again.
///
/// `AppIcon-simple.png` is pre-rounded into the standard macOS shape at build time
/// (`scripts/make-simple-icon.swift`), so this just loads it. No-op when unbundled.
@MainActor
enum AppIconController {
    static func apply(useSimple: Bool) {
        let simple: NSImage? = {
            guard let url = Bundle.main.resourceURL?.appendingPathComponent("AppIcon-simple.png") else { return nil }
            return NSImage(contentsOf: url)
        }()

        // The running app's dock icon (immediate).
        NSApp.applicationIconImage = useSimple ? simple : nil

        // The persistent bundle icon, shown even when closed — only meaningful for a
        // real `.app` (skip `swift run`, and ignore failures on a read-only location).
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension == "app" else { return }
        NSWorkspace.shared.setIcon(useSimple ? simple : nil, forFile: bundleURL.path, options: [])
    }
}
