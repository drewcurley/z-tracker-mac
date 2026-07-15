import Testing
@testable import TrackerCore

@Suite("Recorder destinations (T-035.7)")
struct RecorderDestinationsTests {
    private func locs(_ pairs: [(Int, (Int, Int)?)]) -> [OverworldScreenCoordinate?] {
        var a = [OverworldScreenCoordinate?](repeating: nil, count: 9)
        for (i, p) in pairs { a[i] = p.map { OverworldScreenCoordinate(x: $0.0, y: $0.1) } }
        return a
    }

    @Test("no recorder → no destinations")
    func noRecorder() {
        let dt = DungeonTrackerInstance()
        dt.dungeon(0).toggleTriforce()
        let d = RecorderDestinations.compute(
            haveRecorder: false, dungeonTracker: dt, hideDungeonNumbers: false,
            dungeonLocations: locs([]), toNewDungeons: true, toUnbeatenDungeons: false)
        #expect(d.isEmpty)
    }

    @Test("default (beaten + new): only located dungeons with triforce")
    func beatenNew() {
        let dt = DungeonTrackerInstance()
        dt.dungeon(0).toggleTriforce() // level 1 beaten
        dt.dungeon(2).toggleTriforce() // level 3 beaten (but not located below)
        // Level 1 located at (7,3); level 3 not located.
        let d = RecorderDestinations.compute(
            haveRecorder: true, dungeonTracker: dt, hideDungeonNumbers: false,
            dungeonLocations: locs([(0, (7, 3))]),
            toNewDungeons: true, toUnbeatenDungeons: false)
        #expect(d.count == 1)
        #expect(d.first?.coordinate == OverworldScreenCoordinate(x: 7, y: 3))
        #expect(d.first?.slot == 0)
    }

    @Test("unbeaten + new: dungeons WITHOUT triforce that are located")
    func unbeatenNew() {
        let dt = DungeonTrackerInstance()
        dt.dungeon(0).toggleTriforce() // level 1 beaten → excluded when unbeaten=on
        let d = RecorderDestinations.compute(
            haveRecorder: true, dungeonTracker: dt, hideDungeonNumbers: false,
            dungeonLocations: locs([(0, (7, 3)), (1, (12, 3))]),
            toNewDungeons: true, toUnbeatenDungeons: true)
        // Only level 2 qualifies (unbeaten + located); level 1 is beaten.
        #expect(d.count == 1)
        #expect(d.first?.slot == 1)
        #expect(d.first?.coordinate == OverworldScreenCoordinate(x: 12, y: 3))
    }

    @Test("beaten + vanilla (not new): fixed 1Q screens regardless of location")
    func beatenVanilla() {
        let dt = DungeonTrackerInstance()
        dt.dungeon(0).toggleTriforce()
        dt.dungeon(4).toggleTriforce() // level 5
        let d = RecorderDestinations.compute(
            haveRecorder: true, dungeonTracker: dt, hideDungeonNumbers: false,
            dungeonLocations: locs([]), // nothing located, but vanilla mode ignores that
            toNewDungeons: false, toUnbeatenDungeons: false)
        #expect(d.count == 2)
        let coords = Set(d.map(\.coordinate))
        #expect(coords.contains(OverworldScreenCoordinate(x: 7, y: 3)))   // D1 vanilla
        #expect(coords.contains(OverworldScreenCoordinate(x: 11, y: 0)))  // D5 vanilla
    }
}
