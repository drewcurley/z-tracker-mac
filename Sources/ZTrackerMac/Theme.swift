import AppKit
import SwiftUI

/// Semantic surface/border tokens for the light/dark theme (T-188).
///
/// A **real** light theme = dark text on light backgrounds. So the neutral *surfaces*
/// swap (black/dark boxes → light in Light mode; borders go darker), while **text keeps
/// using `.primary`/`.secondary`**, which already adapt (light in Dark, dark in Light).
/// Game sprites are black-keyed transparent (see the atlases), so they render fine on the
/// light boxes; the black fills behind them are what need to become light.
///
/// `adaptive(...)` resolves against the app appearance (set by the theme picker, T-187).
enum Theme {
    /// An item / room box fill — black in Dark, light in Light (sprites sit on top).
    static let boxFill = adaptive(dark: .black, light: NSColor(white: 0.90, alpha: 1))
    /// A card / section background.
    static let cardFill = adaptive(dark: NSColor(white: 0.10, alpha: 1),
                                   light: NSColor(white: 0.975, alpha: 1))
    /// A raised sub-panel / control background.
    static let panelFill = adaptive(dark: NSColor(white: 0.14, alpha: 1),
                                    light: NSColor(white: 0.93, alpha: 1))
    /// A neutral border.
    static let border = adaptive(dark: NSColor(white: 0.28, alpha: 1),
                                 light: NSColor(white: 0.66, alpha: 1))
    /// A faint hairline separator.
    static let hairline = adaptive(dark: NSColor(white: 0.20, alpha: 1),
                                   light: NSColor(white: 0.82, alpha: 1))
    /// The window canvas behind the cards.
    static let canvas = adaptive(dark: NSColor(white: 0.13, alpha: 1),
                                 light: NSColor(white: 0.88, alpha: 1))
    /// Notes text: the green "terminal" look in Dark, plain black in Light where green
    /// on a light field was too low-contrast (T-188, user request).
    static let notesText = adaptive(dark: .systemGreen, light: .black)
    /// "Has a hint / located" gold — bright yellow in Dark, a dark goldenrod in Light so
    /// it reads on the light-grey hint chips (T-188, user request).
    static let hint = adaptive(dark: .systemYellow, light: NSColor(red: 0.5, green: 0.36, blue: 0, alpha: 1))

    /// A `Color` that resolves per the app appearance (light vs dark).
    static func adaptive(dark: NSColor, light: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua ? light : dark
        })
    }
}
