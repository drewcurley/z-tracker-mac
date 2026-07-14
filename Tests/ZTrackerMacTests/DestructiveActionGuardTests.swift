import Testing
@testable import ZTrackerMac

@Suite("Destructive-action guard (T-051)")
@MainActor
struct DestructiveActionGuardTests {
    @Test("runs immediately unless confirmFirst is set, which queues instead")
    func routing() {
        var pending: DestructiveAction?
        var ran = false

        // confirmFirst false (e.g. run not started) → fires now, nothing queued.
        runOrConfirm(confirmFirst: false, into: &pending,
                     title: "t", message: "m", confirmLabel: "c") { ran = true }
        #expect(ran)
        #expect(pending == nil)

        // confirmFirst true (e.g. run started, even if paused) → queued, not run.
        ran = false
        runOrConfirm(confirmFirst: true, into: &pending,
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
