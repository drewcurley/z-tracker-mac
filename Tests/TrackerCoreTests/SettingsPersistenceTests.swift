import Testing
import Foundation
@testable import TrackerCore

/// T-004.2 — the startup settings (door inference et al.) persist across launches.
@Suite("Startup-settings persistence (T-004.2)")
struct SettingsPersistenceTests {
    /// A fresh isolated UserDefaults suite plus its cleanup. Callers `defer` the
    /// cleanup so tests never leak a persistent domain to disk or touch the real
    /// app domain.
    private func makeStore() -> (store: UserDefaults, cleanup: () -> Void) {
        let name = "test.settings.\(UUID().uuidString)"
        let s = UserDefaults(suiteName: name)!
        return (s, { s.removePersistentDomain(forName: name) })
    }

    @Test("a saved setting is restored on the next launch")
    func roundTrips() {
        let (s, cleanup) = makeStore(); defer { cleanup() }

        // Launch 1: enable persistence, flip settings, commit (quest start).
        let first = TrackerOptions()
        first.enableSettingsPersistence(store: s)
        first.doDoorInference = true
        first.boardInsteadOfLevel = true
        first.defaultToNonDescript = true
        first.saveSettings()

        // Launch 2: a fresh options loads the saved values over defaults.
        let second = TrackerOptions()
        second.enableSettingsPersistence(store: s)
        #expect(second.doDoorInference)          // was default false
        #expect(second.boardInsteadOfLevel)
        #expect(second.defaultToNonDescript)
        #expect(second.showBasementInfo)         // untouched → keeps default true
    }

    @Test("the broadcast size (enum) and hidden-tiles map persist")
    func enumAndDictPersist() {
        let (s, cleanup) = makeStore(); defer { cleanup() }
        let first = TrackerOptions()
        first.enableSettingsPersistence(store: s)
        first.broadcastWindowSize = .twoThirds
        first.hiddenOverworldTiles[.sword3] = true
        first.saveSettings()

        let second = TrackerOptions()
        second.enableSettingsPersistence(store: s)
        #expect(second.broadcastWindowSize == .twoThirds)
        #expect(second.hiddenOverworldTiles[.sword3] == true)
        #expect(second.hiddenOverworldTiles[.sword2] == false)   // default kept
    }

    @Test("without saveSettings, nothing is written")
    func noSaveNoPersist() {
        let (s, cleanup) = makeStore(); defer { cleanup() }
        let first = TrackerOptions()
        first.enableSettingsPersistence(store: s)
        first.doDoorInference = true          // changed but not committed
        // no saveSettings()

        let second = TrackerOptions()
        second.enableSettingsPersistence(store: s)
        #expect(!second.doDoorInference)      // stays default
    }

    @Test("plain TrackerOptions never touches the store")
    func noPersistenceByDefault() {
        let (s, cleanup) = makeStore(); defer { cleanup() }
        let o = TrackerOptions()
        o.doDoorInference = true
        o.saveSettings()                      // no store enabled → no-op
        #expect(s.dictionary(forKey: "ztracker.settings.bools") == nil)
    }

    @Test("every persisted key path round-trips both values")
    func allKeyPathsRoundTrip() {
        // Flip everything on, save, reload, expect all true.
        let (s, cleanup) = makeStore(); defer { cleanup() }
        let first = TrackerOptions()
        first.enableSettingsPersistence(store: s)
        for kp in TrackerOptions.persistedBoolKeyPaths.values { first[keyPath: kp] = true }
        first.saveSettings()

        let second = TrackerOptions()
        second.enableSettingsPersistence(store: s)
        for kp in TrackerOptions.persistedBoolKeyPaths.values {
            #expect(second[keyPath: kp], "key path did not persist true")
        }
    }
}
