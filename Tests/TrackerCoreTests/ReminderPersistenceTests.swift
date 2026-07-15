import Foundation
import Testing
@testable import TrackerCore

@Suite("Reminder settings persistence (T-004.1)")
struct ReminderPersistenceTests {
    /// A throwaway, isolated defaults suite so tests never touch `.standard`.
    private func makeStore() -> UserDefaults {
        let suite = "ztracker.test.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test("plain TrackerOptions() never writes to defaults")
    func noPersistenceWithoutOptIn() {
        let store = makeStore()
        let o = TrackerOptions()          // no store enabled
        o.reminderVolume = 77
        o.voiceReminders[.blockers] = false
        #expect(store.object(forKey: "ztracker.reminders.volume") == nil)
    }

    @Test("volume, voice, visual, and preferred voice round-trip a relaunch")
    func roundTrip() {
        let store = makeStore()

        // First "launch": change some settings.
        let first = TrackerOptions.withReminderPersistence(store: store)
        first.reminderVolume = 65
        first.voiceReminders[.blockers] = false
        first.visualReminders[.dungeonFeedback] = false
        first.preferredVoiceIdentifier = "com.example.voice"

        // Second "launch" with the same store: values are restored.
        let second = TrackerOptions.withReminderPersistence(store: store)
        #expect(second.reminderVolume == 65)
        #expect(second.voiceReminders[.blockers] == false)
        #expect(second.visualReminders[.dungeonFeedback] == false)
        #expect(second.preferredVoiceIdentifier == "com.example.voice")
        // Untouched categories keep their defaults.
        #expect(second.voiceReminders[.coastItem] == true)
    }

    @Test("Disable all persists")
    func disableAllPersists() {
        let store = makeStore()
        let first = TrackerOptions.withReminderPersistence(store: store)
        first.disableAllReminders()

        let second = TrackerOptions.withReminderPersistence(store: store)
        #expect(second.voiceReminders.values.allSatisfy { $0 == false })
        #expect(second.visualReminders.values.allSatisfy { $0 == false })
    }

    @Test("a category absent from the save keeps its default (forward-compatible)")
    func missingCategoryKeepsDefault() {
        let store = makeStore()
        // Simulate an older save that only knew two categories.
        store.set(["blockers": false], forKey: "ztracker.reminders.voice")

        let o = TrackerOptions.withReminderPersistence(store: store)
        #expect(o.voiceReminders[.blockers] == false)           // from the save
        #expect(o.voiceReminders[.dungeonFeedback] == true)     // default preserved
    }
}
