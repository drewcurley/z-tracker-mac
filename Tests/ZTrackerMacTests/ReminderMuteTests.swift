import Testing
import TrackerCore
@testable import ZTrackerMac

/// T-250 — "Disable all" mutes every reminder but still logs it, greyed.
@Suite("Reminder mute (T-250)")
@MainActor
struct ReminderMuteTests {
    @Test("muted: nothing shown, but the reminder is logged as muted")
    func mutedLogsOnly() {
        let options = TrackerOptions()
        options.voiceReminders = options.voiceReminders.mapValues { _ in false }   // keep the test silent
        options.remindersMuted = true
        let reminders = ReminderController()
        reminders.handle([.triforceCount(2)], options: options)
        #expect(reminders.visible.isEmpty)
        #expect(reminders.log.entries.first?.muted == true)
    }

    @Test("unmuted: shown and logged normally")
    func unmutedShows() {
        let options = TrackerOptions()
        options.voiceReminders = options.voiceReminders.mapValues { _ in false }
        let reminders = ReminderController()
        reminders.handle([.triforceCount(2)], options: options)
        #expect(reminders.visible.count == 1)
        #expect(reminders.log.entries.first?.muted == false)
    }

    @Test("muting clears on-screen reminders but keeps an Undo toast")
    func silenceNowKeepsActions() {
        let reminders = ReminderController()
        reminders.toast("plain", duration: .seconds(60))
        reminders.toast("Inventory reset", duration: .seconds(60), action: .init(title: "Undo") {})
        reminders.silenceNow()
        #expect(reminders.visible.map(\.text) == ["Inventory reset"])
    }
}
