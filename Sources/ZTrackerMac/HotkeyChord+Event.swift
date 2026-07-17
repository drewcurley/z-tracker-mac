import AppKit
import TrackerCore

extension HotkeyChord {
    /// Build a chord from a key-down event (T-132). One of Shift/Control/Option is
    /// captured (Command is reserved for the menus and rejected). Letters/digits store
    /// the character; any other key stores its raw Mac key code as `\nnn`.
    init?(nsEvent event: NSEvent) {
        let mods = event.modifierFlags
        if mods.contains(.command) { return nil }
        var modifier = HotkeyChord.Modifier.none
        if mods.contains(.shift) { modifier = .shift }
        else if mods.contains(.control) { modifier = .control }
        else if mods.contains(.option) { modifier = .option }
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if chars.count == 1, let ch = chars.first, ch.isLetter || ch.isNumber {
            self.init(modifier: modifier, key: String(ch))
        } else {
            self.init(modifier: modifier, key: "\\\(event.keyCode)")
        }
    }
}
