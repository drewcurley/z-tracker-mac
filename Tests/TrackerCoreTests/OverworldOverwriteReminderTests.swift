import Testing
@testable import TrackerCore

@Suite("Overworld-overwrite reminder (T-096)")
struct OverworldOverwriteReminderTests {
    @Test("destructive change of a real mark → reminder with from/to")
    func destructiveChange() {
        let a = OverworldOverwriteReminder.announcement(
            old: .doorRepair, new: .moneyMakingGame, coordLabel: "C4")
        #expect(a == .overworldOverwrite(coordLabel: "C4", from: "Door repair", to: "Money making game"))
        #expect(a?.displayText == "You changed C4 from Door repair to Money making game")
        #expect(a?.category == .overworldOverwrites)
    }

    @Test("no reminder for a fresh mark, a no-op, or a don't-care original")
    func nonDestructive() {
        // Marking an unmarked tile is not an overwrite.
        #expect(OverworldOverwriteReminder.announcement(old: .unmarked, new: .doorRepair, coordLabel: "A1") == nil)
        // Same value → no change.
        #expect(OverworldOverwriteReminder.announcement(old: .doorRepair, new: .doorRepair, coordLabel: "A1") == nil)
        // Overwriting a don't-care tile isn't destructive.
        #expect(OverworldOverwriteReminder.announcement(old: .dontCare, new: .moneyMakingGame, coordLabel: "A1") == nil)
    }

    @Test("refining an unknown secret into a sized secret is not reported")
    func unknownSecretRefinement() {
        #expect(OverworldOverwriteReminder.announcement(
            old: .secret(.unknown), new: .secret(.large), coordLabel: "B3") == nil)
        // But changing a KNOWN secret to something else is reported.
        #expect(OverworldOverwriteReminder.announcement(
            old: .secret(.large), new: .doorRepair, coordLabel: "B3") != nil)
    }
}
