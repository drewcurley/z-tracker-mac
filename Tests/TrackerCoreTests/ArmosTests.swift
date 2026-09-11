import Testing
@testable import TrackerCore

@Suite("Armos eligibility, deduction & alert (T-223)")
struct ArmosTests {
    /// The five eligible screens (col, row) — must match `Masks.armos` and have nicknames.
    static let eligible: [(x: Int, y: Int, name: String)] = [
        (12, 1, "Lost Hills Armos"),   // B13
        (4, 2, "Grave Armos"),         // C5
        (4, 3, "Death Armos"),         // D5
        (13, 3, "North Forest Armos"), // D14
        (14, 4, "East Forest Armos"),  // E15
    ]

    @Test("every hasArmos screen is one of the five and has a nickname; nothing else does")
    func maskMatchesNames() {
        let instance = OverworldInstance(quest: .first)
        var found: [(Int, Int)] = []
        for y in 0..<8 {
            for x in 0..<16 {
                let named = ArmosLocation.name(column: x, row: y) != nil
                #expect(instance.hasArmos(x: x, y: y) == named, "(\(x),\(y)) mask vs name mismatch")
                if instance.hasArmos(x: x, y: y) { found.append((x, y)) }
            }
        }
        #expect(found.count == 5)
        for e in Self.eligible { #expect(ArmosLocation.name(column: e.x, row: e.y) == e.name) }
    }

    @Test("canMarkArmos: only the five on a vanilla map; anywhere on a custom map")
    func canMark() {
        let m = TrackerModel(quest: .first)
        #expect(m.canMarkArmos(column: 4, row: 2))         // C5 eligible
        #expect(!m.canMarkArmos(column: 0, row: 0))        // not eligible
        #expect(!m.canMarkArmos(column: 5, row: 2))        // next to C5, not eligible
        m.customMapImagePath = "/tmp/whatever.png"
        #expect(m.canMarkArmos(column: 0, row: 0))         // custom map → anywhere
    }

    @Test("deduction auto-marks the fifth once the other four are ruled out")
    func deduction() {
        let m = TrackerModel(quest: .first)
        // Rule out the first four eligible screens with a definite non-armos mark.
        for e in Self.eligible.prefix(4) {
            m.overworldGrid.setMark(.dontCare, column: e.x, row: e.y)
        }
        m.applyArmosDeduction()
        let fifth = Self.eligible[4]
        #expect(m.overworldGrid.mark(column: fifth.x, row: fifth.y) == .armos)
        // The four ruled-out screens are untouched.
        for e in Self.eligible.prefix(4) {
            #expect(m.overworldGrid.mark(column: e.x, row: e.y) == .dontCare)
        }
    }

    @Test("no deduction until exactly four are ruled out")
    func partialNoDeduction() {
        let m = TrackerModel(quest: .first)
        for e in Self.eligible.prefix(3) {   // only three ruled out
            m.overworldGrid.setMark(.dontCare, column: e.x, row: e.y)
        }
        m.applyArmosDeduction()
        for e in Self.eligible where m.overworldGrid.mark(column: e.x, row: e.y) == .armos {
            Issue.record("armos wrongly deduced at (\(e.x),\(e.y)) with only three ruled out")
        }
    }

    @Test("no deduction on a custom map (no fixed vanilla spots)")
    func customMapNoDeduction() {
        let m = TrackerModel(quest: .first)
        m.customMapImagePath = "/tmp/x.png"
        for e in Self.eligible.prefix(4) { m.overworldGrid.setMark(.dontCare, column: e.x, row: e.y) }
        m.applyArmosDeduction()
        let fifth = Self.eligible[4]
        #expect(m.overworldGrid.mark(column: fifth.x, row: fifth.y) == .unmarked)
    }

    @Test("a manual armos mark stays silent — the player already found it")
    func manualMarkNoAlert() {
        let m = TrackerModel(quest: .first)
        m.overworldGrid.setMark(.armos, column: 4, row: 2)   // C5, others still unmarked
        let out = m.pollReminders()
        #expect(!out.contains(.armosLocated(name: "Grave Armos")))
    }

    @Test("a fresh deduction fires the named alert once, then stays quiet")
    func deductionAlertFiresOnce() {
        let m = TrackerModel(quest: .first)
        // Rule out four; the fifth (East Forest Armos, E15) is the remaining eligible screen.
        for e in Self.eligible.filter({ $0.name != "East Forest Armos" }) {
            m.overworldGrid.setMark(.dontCare, column: e.x, row: e.y)
        }
        let first = m.pollReminders()   // this poll auto-deduces + announces
        #expect(first.contains(.armosLocated(name: "East Forest Armos")))
        let second = m.pollReminders()  // already located → no repeat
        #expect(!second.contains(.armosLocated(name: "East Forest Armos")))
    }
}
