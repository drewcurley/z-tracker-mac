import Testing
@testable import ZTrackerMac

@Suite("ReminderAudioPlayer — audio warm-up")
@MainActor
struct ReminderAudioPlayerTests {
    @Test("a bundled clip resolves for warming the audio stack")
    func warmUpClipResolves() {
        // If this is nil the launch warm-up (T-045) silently no-ops — which is
        // exactly the regression this guards: the audio resources moved / were
        // dropped from the bundle.
        let url = ReminderAudioPlayer.warmUpClipURL()
        #expect(url != nil)
        #expect(url?.pathExtension == "m4a")
    }
}
