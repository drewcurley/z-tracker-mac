import Testing
@testable import ZTrackerMac

@Suite("Destructive-action guard (T-051)")
@MainActor
struct DestructiveActionGuardTests {
    @Test("runs immediately when the timer isn't running; confirms when it is")
    func routing() {
        var pending: DestructiveAction?
        var ran = false

        // Not running → the action fires now, nothing is queued.
        runOrConfirm(timerIsRunning: false, into: &pending,
                     title: "t", message: "m", confirmLabel: "c") { ran = true }
        #expect(ran)
        #expect(pending == nil)

        // Running → the action is queued for confirmation, not run yet.
        ran = false
        runOrConfirm(timerIsRunning: true, into: &pending,
                     title: "Change X?", message: "wipes state", confirmLabel: "Change X") { ran = true }
        #expect(!ran)
        #expect(pending != nil)
        #expect(pending?.title == "Change X?")
        #expect(pending?.confirmLabel == "Change X")

        // Confirming performs the queued action.
        pending?.perform()
        #expect(ran)
    }
}
