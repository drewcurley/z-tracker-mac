import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Item Progress bar (T-035.9)")
struct ItemProgressBarTests {
    @Test("empty state: 13 slots, none obtained, base icons")
    func empty() {
        let slots = ItemProgressBar.slots(PlayerComputedStateSummary(), options: ItemIconOptions())
        #expect(slots.count == 13)
        #expect(slots.allSatisfy { !$0.obtained })
        #expect(slots[0].icon == .brownSword) // sword base variant
        #expect(slots[1].icon == .blueCandle)
    }

    @Test("levels pick the right variant and mark obtained")
    func levels() {
        let s = PlayerComputedStateSummary(
            haveRecorder: true, haveRaft: true, swordLevel: 2, candleLevel: 2,
            ringLevel: 1, arrowLevel: 2, boomerangLevel: 1)
        let slots = ItemProgressBar.slots(s, options: ItemIconOptions())
        #expect(slots[0] == .init(icon: .whiteSword, obtained: true))  // sword lvl 2
        #expect(slots[1] == .init(icon: .redCandle, obtained: true))   // candle lvl 2
        #expect(slots[2] == .init(icon: .blueRing, obtained: true))    // ring lvl 1
        #expect(slots[4] == .init(icon: .silverArrow, obtained: true)) // arrow lvl 2
        #expect(slots[7] == .init(icon: .boomerang, obtained: true))   // boomerang lvl 1
        #expect(slots[9] == .init(icon: .recorder, obtained: true))
        #expect(slots[11] == .init(icon: .raft, obtained: true))
    }

    @Test("magical sword at level 3; book/shield follows the option")
    func swordAndBook() {
        let s = PlayerComputedStateSummary(swordLevel: 3, haveBookOrShield: true)
        #expect(ItemProgressBar.slots(s, options: ItemIconOptions(isCurrentlyBook: true))[0]
                == .init(icon: .magicalSword, obtained: true))
        #expect(ItemProgressBar.slots(s, options: ItemIconOptions(isCurrentlyBook: true))[6]
                == .init(icon: .book, obtained: true))
        #expect(ItemProgressBar.slots(s, options: ItemIconOptions(isCurrentlyBook: false))[6]
                == .init(icon: .magicShield, obtained: true))
    }
}
