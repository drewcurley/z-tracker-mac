import Testing
@testable import TrackerCore

@Suite("Gated-item acquisition defaults (T-214)")
struct ItemAcquisitionGateTests {
    @Test("coast item needs the ladder")
    func coast() {
        #expect(!ItemAcquisitionGate.coastReachable(PlayerComputedStateSummary(haveLadder: false)))
        #expect(ItemAcquisitionGate.coastReachable(PlayerComputedStateSummary(haveLadder: true)))
    }

    @Test("white-sword item needs >= 4 hearts (the 4-6 minimum)")
    func whiteSword() {
        #expect(ItemAcquisitionGate.whiteSwordItemMinHearts == 4)
        #expect(!ItemAcquisitionGate.whiteSwordItemReachable(PlayerComputedStateSummary(playerHearts: 3)))
        #expect(ItemAcquisitionGate.whiteSwordItemReachable(PlayerComputedStateSummary(playerHearts: 4)))
        #expect(ItemAcquisitionGate.whiteSwordItemReachable(PlayerComputedStateSummary(playerHearts: 7)))
    }

    @Test("magical sword needs >= 10 hearts (the 10-14 minimum)")
    func magicalSword() {
        #expect(ItemAcquisitionGate.magicalSwordMinHearts == 10)
        #expect(!ItemAcquisitionGate.magicalSwordReachable(PlayerComputedStateSummary(playerHearts: 9)))
        #expect(ItemAcquisitionGate.magicalSwordReachable(PlayerComputedStateSummary(playerHearts: 10)))
        #expect(ItemAcquisitionGate.magicalSwordReachable(PlayerComputedStateSummary(playerHearts: 14)))
    }
}
