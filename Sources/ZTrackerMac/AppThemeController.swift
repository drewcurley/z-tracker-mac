import AppKit
import TrackerCore

/// Applies the user's color-theme choice (T-187) to the whole app by setting
/// `NSApp.appearance` — which cascades to every window (tracker, Settings, Timeline,
/// Broadcast). `system` clears the override so the app follows the OS appearance.
///
/// Note: the game-board art (overworld terrain, item/room sprites, the tile panels
/// with explicit dark fills) is intentionally dark regardless; the theme mainly drives
/// the standard controls and chrome (startup/Settings/menus/timer).
enum AppThemeController {
    static func apply(_ theme: AppTheme) {
        NSApplication.shared.appearance = appearance(for: theme)
    }

    static func appearance(for theme: AppTheme) -> NSAppearance? {
        switch theme {
        case .dark: NSAppearance(named: .darkAqua)
        case .light: NSAppearance(named: .aqua)
        case .system: nil   // follow the OS
        }
    }
}
