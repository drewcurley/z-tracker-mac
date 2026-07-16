import Testing
@testable import TrackerCore

@Suite("Speech pronunciation fixups (T-086)")
struct SpeechTextTests {
    @Test("triforce → try force, singular and plural, case-insensitive")
    func triforce() {
        #expect(SpeechText.spoken("You now have one triforce") == "You now have one try force")
        #expect(SpeechText.spoken("You now have 3 triforces") == "You now have 3 try forces")
        #expect(SpeechText.spoken("You are triforce and go") == "You are try force and go")
        // Plural handled before singular, so "triforces" isn't left as "try forcs".
        #expect(SpeechText.spoken("triforces") == "try forces")
        #expect(SpeechText.spoken("Triforce") == "try force")   // case-insensitive
    }

    @Test("leaves other text untouched")
    func passthrough() {
        #expect(SpeechText.spoken("You can revisit dungeon 2 — Need ladder")
                == "You can revisit dungeon 2 — Need ladder")
        #expect(SpeechText.spoken("") == "")
    }
}
