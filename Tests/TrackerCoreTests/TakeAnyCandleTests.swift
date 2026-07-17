import Testing
@testable import TrackerCore

@Suite("Take-any candle auto-activates the blue candle (T-103)")
struct TakeAnyCandleTests {
    @Test("selecting candle on any take-any slot turns on hasBlueCandle")
    func candleActivatesCandle() {
        let p = PlayerProgressAndTakeAnyHearts()
        #expect(!p.hasBlueCandle)
        p.takeAnyHearts[2] = .takenCandle
        #expect(p.hasBlueCandle)
    }

    @Test("non-candle take-any states don't touch hasBlueCandle")
    func othersDoNotActivate() {
        let p = PlayerProgressAndTakeAnyHearts()
        p.takeAnyHearts[0] = .takenHeart
        p.takeAnyHearts[1] = .takenPotion
        #expect(!p.hasBlueCandle)
    }

    @Test("removing the candle does NOT clear a candle held from elsewhere")
    func doesNotClear() {
        let p = PlayerProgressAndTakeAnyHearts(hasBlueCandle: true)
        p.takeAnyHearts[0] = .takenHeart   // no candle anywhere
        #expect(p.hasBlueCandle)           // still on (came from elsewhere)
    }
}
