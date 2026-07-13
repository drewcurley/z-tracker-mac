import Testing
@testable import TrackerCore

@Suite("ITEMS")
struct ITEMSTests {
    @Test("indices pin the reference's ITEMS module value-for-value")
    func indicesPinReference() {
        #expect(ITEMS.bookOrShield == 0)
        #expect(ITEMS.boomerang == 1)
        #expect(ITEMS.bow == 2)
        #expect(ITEMS.powerBracelet == 3)
        #expect(ITEMS.ladder == 4)
        #expect(ITEMS.magicBoomerang == 5)
        #expect(ITEMS.anyKey == 6)
        #expect(ITEMS.raft == 7)
        #expect(ITEMS.recorder == 8)
        #expect(ITEMS.redCandle == 9)
        #expect(ITEMS.redRing == 10)
        #expect(ITEMS.silverArrow == 11)
        #expect(ITEMS.wand == 12)
        #expect(ITEMS.whiteSword == 13)
        #expect(ITEMS.heartContainer == 14)
        #expect(ITEMS.count == 15)
        #expect(Box.itemCount == ITEMS.count)
    }
}

@Suite("PlayerComputedStateSummary")
struct PlayerComputedStateSummaryTests {
    /// Convenience: compute with empty foundation and a given dungeon
    /// tracker + WSMS flag.
    private func compute(
        dungeonTracker: DungeonTrackerInstance = DungeonTrackerInstance(),
        startingItems: StartingItemsAndExtras = StartingItemsAndExtras(),
        progress: PlayerProgressAndTakeAnyHearts = PlayerProgressAndTakeAnyHearts(),
        isWSMSReplacedByBU: Bool = false
    ) -> PlayerComputedStateSummary {
        PlayerComputedStateSummary.compute(
            dungeonTracker: dungeonTracker,
            startingItems: startingItems,
            progress: progress,
            isWSMSReplacedByBU: isWSMSReplacedByBU
        )
    }

    @Test("a fresh game derives all defaults (hearts = 3, everything else false/0)")
    func freshDefaults() {
        let s = compute()
        #expect(s == PlayerComputedStateSummary()) // memberwise defaults
        #expect(s.playerHearts == 3)
        #expect(s.swordLevel == 0)
        #expect(s.haveLadder == false)
    }

    @Test("obtained boxes map to the right fields by ITEMS index")
    func boxItemScan() {
        let inst = DungeonTrackerInstance()
        let boxes = inst.allBoxes()
        // Mark distinct boxes with distinct obtained items.
        boxes[0].set(cellCurrent: ITEMS.recorder, playerHas: .yes)
        boxes[1].set(cellCurrent: ITEMS.ladder, playerHas: .yes)
        boxes[2].set(cellCurrent: ITEMS.anyKey, playerHas: .yes)
        boxes[3].set(cellCurrent: ITEMS.powerBracelet, playerHas: .yes)
        boxes[4].set(cellCurrent: ITEMS.raft, playerHas: .yes)
        boxes[5].set(cellCurrent: ITEMS.redCandle, playerHas: .yes)
        boxes[6].set(cellCurrent: ITEMS.bookOrShield, playerHas: .yes)
        boxes[7].set(cellCurrent: ITEMS.bow, playerHas: .yes)
        boxes[8].set(cellCurrent: ITEMS.wand, playerHas: .yes)
        boxes[9].set(cellCurrent: ITEMS.redRing, playerHas: .yes)
        boxes[10].set(cellCurrent: ITEMS.silverArrow, playerHas: .yes)
        boxes[11].set(cellCurrent: ITEMS.magicBoomerang, playerHas: .yes)
        boxes[12].set(cellCurrent: ITEMS.whiteSword, playerHas: .yes)

        let s = compute(dungeonTracker: inst)
        #expect(s.haveRecorder)
        #expect(s.haveLadder)
        #expect(s.haveAnyKey)
        #expect(s.havePowerBracelet)
        #expect(s.haveRaft)
        #expect(s.candleLevel == 2)
        #expect(s.haveBookOrShield)
        #expect(s.haveBow)
        #expect(s.haveWand)
        #expect(s.ringLevel == 2)
        #expect(s.arrowLevel == 2)
        #expect(s.boomerangLevel == 2)
        #expect(s.swordLevel == 2)
    }

    @Test("only .yes boxes count — .skipped and .no do not contribute possession")
    func onlyYesCounts() {
        let inst = DungeonTrackerInstance()
        let boxes = inst.allBoxes()
        boxes[0].set(cellCurrent: ITEMS.ladder, playerHas: .skipped)
        boxes[1].set(cellCurrent: ITEMS.raft, playerHas: .no)
        let s = compute(dungeonTracker: inst)
        #expect(s.haveLadder == false)
        #expect(s.haveRaft == false)
    }

    @Test("heart containers each add 1; take-any hearts add 1 only when a heart (raw 1)")
    func hearts() {
        let inst = DungeonTrackerInstance()
        let boxes = inst.allBoxes()
        boxes[0].set(cellCurrent: ITEMS.heartContainer, playerHas: .yes)
        boxes[1].set(cellCurrent: ITEMS.heartContainer, playerHas: .yes)

        let progress = PlayerProgressAndTakeAnyHearts()
        progress.takeAnyHearts[0] = .takenHeart          // +1
        progress.takeAnyHearts[1] = .takenPotionOrCandle // +0
        progress.takeAnyHearts[2] = .takenHeart          // +1

        let starting = StartingItemsAndExtras(maxHeartsDifferential: 2)

        let s = compute(dungeonTracker: inst, startingItems: starting, progress: progress)
        // 3 base + 2 heart boxes + 2 take-any hearts + 2 differential
        #expect(s.playerHearts == 9)
    }

    @Test("candle/ring/arrow/sword levels take the max across sources")
    func levelMaxSemantics() {
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasBlueCandle = true // candle 1
        progress.hasWoodSword = true  // sword 1
        progress.hasBlueRing = true   // ring 1
        progress.hasWoodArrow = true  // arrow 1

        // Boxes raise candle to 2 and ring to 2; sword box to 2.
        let inst = DungeonTrackerInstance()
        let boxes = inst.allBoxes()
        boxes[0].set(cellCurrent: ITEMS.redCandle, playerHas: .yes)
        boxes[1].set(cellCurrent: ITEMS.redRing, playerHas: .yes)
        boxes[2].set(cellCurrent: ITEMS.whiteSword, playerHas: .yes)

        let s = compute(dungeonTracker: inst, progress: progress)
        #expect(s.candleLevel == 2)
        #expect(s.ringLevel == 2)
        #expect(s.arrowLevel == 1) // only wood arrow present
        #expect(s.swordLevel == 2) // white sword box beats wood sword
    }

    @Test("magical sword (progress) sets sword level 3, but WSMS-as-BU suppresses it")
    func magicalSwordProgressAndWSMS() {
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasMagicalSword = true

        #expect(compute(progress: progress).swordLevel == 3)
        #expect(compute(progress: progress, isWSMSReplacedByBU: true).swordLevel == 0)
    }

    @Test("starting magical sword always gives sword 3 even under WSMS-as-BU (it's a real sword)")
    func startingMagicalSwordIgnoresWSMS() {
        let starting = StartingItemsAndExtras(hasMagicalSword: true)
        #expect(compute(startingItems: starting).swordLevel == 3)
        #expect(compute(startingItems: starting, isWSMSReplacedByBU: true).swordLevel == 3)
    }

    @Test("white sword box is suppressed by WSMS-as-BU; starting white sword is not")
    func whiteSwordBoxVsStartingUnderWSMS() {
        let inst = DungeonTrackerInstance()
        inst.allBoxes()[0].set(cellCurrent: ITEMS.whiteSword, playerHas: .yes)
        #expect(compute(dungeonTracker: inst, isWSMSReplacedByBU: true).swordLevel == 0)

        let starting = StartingItemsAndExtras(hasWhiteSword: true)
        #expect(compute(startingItems: starting, isWSMSReplacedByBU: true).swordLevel == 2)
    }

    @Test("standalone ladderBox/sword2Box drive coast item / white-sword item")
    func standaloneBoxesDeriveCoastAndWhiteSwordItem() {
        let inst = DungeonTrackerInstance()
        // both are pre-set to .skipped with empty cell -> not done -> false
        #expect(compute(dungeonTracker: inst).haveCoastItem == false)
        #expect(compute(dungeonTracker: inst).haveWhiteSwordItem == false)

        inst.ladderBox.set(cellCurrent: ITEMS.ladder, playerHas: .yes)
        inst.sword2Box.set(cellCurrent: ITEMS.whiteSword, playerHas: .skipped)
        let s = compute(dungeonTracker: inst)
        #expect(s.haveCoastItem)       // ladderBox now done
        #expect(s.haveWhiteSwordItem)  // sword2Box done (skipped-with-item counts)
    }

    @Test("every starting item flag maps to the right derived field")
    func startingItemsMapping() {
        let starting = StartingItemsAndExtras(
            hasSilverArrow: true,
            hasBow: true,
            hasWand: true,
            hasRedCandle: true,
            hasBoomerang: true,
            hasRedRing: true,
            hasPowerBracelet: true,
            hasLadder: true,
            hasRaft: true,
            hasRecorder: true,
            hasAnyKey: true,
            hasBook: true
        )
        let s = compute(startingItems: starting)
        #expect(s.arrowLevel == 2)
        #expect(s.haveBow)
        #expect(s.haveWand)
        #expect(s.candleLevel == 2)
        #expect(s.boomerangLevel == 1)
        #expect(s.ringLevel == 2)
        #expect(s.havePowerBracelet)
        #expect(s.haveLadder)
        #expect(s.haveRaft)
        #expect(s.haveRecorder)
        #expect(s.haveAnyKey)
        #expect(s.haveBookOrShield)
    }

    @Test("starting magic boomerang beats starting boomerang (level 2)")
    func magicBoomerangLevel() {
        let starting = StartingItemsAndExtras(hasBoomerang: true, hasMagicBoomerang: true)
        #expect(compute(startingItems: starting).boomerangLevel == 2)
    }

    @Test("TrackerModel.playerComputedStateSummary matches a direct compute")
    func trackerModelConvenience() {
        let model = TrackerModel(isWSMSReplacedByBU: true)
        model.startingItemsAndExtras.hasLadder = true
        model.playerProgress.hasWoodSword = true
        model.dungeonTracker.allBoxes()[0].set(cellCurrent: ITEMS.bow, playerHas: .yes)

        let direct = PlayerComputedStateSummary.compute(
            dungeonTracker: model.dungeonTracker,
            startingItems: model.startingItemsAndExtras,
            progress: model.playerProgress,
            isWSMSReplacedByBU: true
        )
        #expect(model.playerComputedStateSummary == direct)
        #expect(model.playerComputedStateSummary.haveLadder)
        #expect(model.playerComputedStateSummary.haveBow)
        #expect(model.playerComputedStateSummary.swordLevel == 1)
    }
}
