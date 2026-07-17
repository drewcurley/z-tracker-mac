import Testing
@testable import TrackerCore

@Suite("Reminder log (T-102)")
struct ReminderLogTests {
    @Test("newest first, distinct ids for duplicate text")
    func order() {
        let log = ReminderLog()
        log.append("a")
        log.append("b")
        log.append("b")
        #expect(log.entries.map(\.text) == ["b", "b", "a"])   // newest first
        #expect(Set(log.entries.map(\.id)).count == 3)        // distinct ids
    }

    @Test("caps at the limit, dropping the oldest")
    func cap() {
        let log = ReminderLog(cap: 3)
        for t in ["1", "2", "3", "4", "5"] { log.append(t) }
        #expect(log.entries.map(\.text) == ["5", "4", "3"])   // oldest (1,2) dropped
        #expect(log.entries.count == 3)
    }

    @Test("clear empties it")
    func clear() {
        let log = ReminderLog()
        log.append("x")
        log.clear()
        #expect(log.entries.isEmpty)
    }

    @Test("stores the fire-time and icons (T-122)")
    func timestampAndIcons() {
        let log = ReminderLog()
        log.append("You can revisit dungeon 3", elapsedSeconds: 1863,
                   icons: [.sword(level: 3), .rightArrow, .dungeon(3)])
        let e = log.entries.first
        #expect(e?.elapsedSeconds == 1863)
        #expect(e?.icons == [.sword(level: 3), .rightArrow, .dungeon(3)])
        // Defaults keep older call sites working.
        log.append("plain")
        #expect(log.entries.first?.elapsedSeconds == 0)
        #expect(log.entries.first?.icons.isEmpty == true)
    }
}
