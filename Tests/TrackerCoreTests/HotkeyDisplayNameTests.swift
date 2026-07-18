import Testing
@testable import TrackerCore

/// The editor's human-readable key labels (T-135) — no raw `\nnn` shown.
struct HotkeyDisplayNameTests {
    @Test func lettersAndDigits() {
        #expect(HotkeyChord(key: "a").displayName == "A")
        #expect(HotkeyChord(key: "7").displayName == "7")
        #expect(HotkeyChord(modifier: .shift, key: "k").displayName == "⇧ K")
    }

    @Test func punctuationCodesResolve() {
        #expect(HotkeyChord(key: "\\27").displayName == "-")
        #expect(HotkeyChord(key: "\\24").displayName == "=")
        #expect(HotkeyChord(key: "\\33").displayName == "[")
        #expect(HotkeyChord(modifier: .option, key: "\\44").displayName == "⌥ /")
    }

    @Test func functionAndNavAndArrows() {
        #expect(HotkeyChord(key: "\\100").displayName == "F8")
        #expect(HotkeyChord(modifier: .shift, key: "\\98").displayName == "⇧ F7")
        #expect(HotkeyChord(key: "\\121").displayName == "Page Down")
        #expect(HotkeyChord(key: "\\115").displayName == "Home")
        #expect(HotkeyChord(key: "\\124").displayName == "→")
        #expect(HotkeyChord(key: "\\49").displayName == "Space")
    }

    @Test func unmappedCodeFallsBackToRaw() {
        #expect(HotkeyChord(key: "\\200").displayName == "\\200")
    }
}
