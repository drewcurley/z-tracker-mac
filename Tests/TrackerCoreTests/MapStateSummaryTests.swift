import Testing
@testable import TrackerCore

@Suite("MapStateSummary (recomputeMapStateSummary)")
struct MapStateSummaryTests {
    /// A nothingable, non-always-empty first-quest screen — safe to place a
    /// mark on (the tile is processed; no terrain tool interferes). Computed
    /// from the masks.
    static let safeScreen = (x: 0, y: 7)
    static let safeScreen2 = (x: 1, y: 2)
    /// A bombable-only, non-always-empty first-quest screen (from the masks).
    static let bombableScreen = (x: 0, y: 1)

    private func compute(
        grid: OverworldGrid = OverworldGrid(),
        quest: OverworldQuest = .first,
        dungeonTracker: DungeonTrackerInstance = DungeonTrackerInstance(),
        playerState: PlayerComputedStateSummary = PlayerComputedStateSummary(),
        progress: PlayerProgressAndTakeAnyHearts = PlayerProgressAndTakeAnyHearts(),
        drawRoutes: Bool = false,
        routesCanScreenScroll: Bool = false,
        mirrorOverworld: Bool = false
    ) -> MapStateSummary {
        MapStateSummary.compute(
            grid: grid,
            instance: OverworldInstance(quest: quest),
            dungeonTracker: dungeonTracker,
            playerState: playerState,
            progress: progress,
            drawRoutes: drawRoutes,
            routesCanScreenScroll: routesCanScreenScroll,
            mirrorOverworld: mirrorOverworld
        )
    }

    @Test("empty first-quest map, empty-handed: pinned counts match the masks")
    func emptyFirstQuestCounts() {
        let s = compute()
        #expect(s.owSpotsRemain == 73)                 // 128 - 55 always-empty
        #expect(s.owGettableLocations.trueCount == 28) // nothingable screens
        #expect(s.owRouteworthySpots.trueCount == 28)
        #expect(s.owWhistleSpotsRemain.count == 1)
        #expect(s.owPowerBraceletSpotsRemain == 4)
        #expect(s.dungeonLocations.allSatisfy { $0 == nil })
        #expect(s.anyRoadLocations.allSatisfy { $0 == nil })
        #expect(s.armosLocation == nil)
        #expect(s.sword1Location == nil && s.sword2Location == nil && s.sword3Location == nil)
        #expect(!s.magsCaveFound && !s.woodSwordCaveFound && !s.foundBlueRingShop
            && !s.foundBookShop && !s.foundCandleShop && !s.foundArrowShop
            && !s.foundBombShop && !s.havePotionLetter)
    }

    @Test("a bombable screen is gettable only once the player has bombs")
    func bombableGatedByBombs() {
        let (x, y) = Self.bombableScreen
        #expect(compute().owGettableLocations[x, y] == false)

        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasBombs = true
        let s = compute(progress: progress)
        #expect(s.owGettableLocations[x, y] == true)
        #expect(s.owRouteworthySpots[x, y] == true)
    }

    @Test("dungeon 1-8: located, and routeworthy until complete")
    func dungeonLocationAndCompletion() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.dungeon(1), column: x, row: y)
        let dt = DungeonTrackerInstance()

        var s = compute(grid: grid, dungeonTracker: dt)
        #expect(s.dungeonLocations[0] == OverworldScreenCoordinate(x: x, y: y))
        #expect(s.owRouteworthySpots[x, y] == true) // not complete yet

        // Complete dungeon 1: triforce + all boxes done.
        dt.dungeon(0).toggleTriforce()
        for box in dt.dungeon(0).boxes { box.set(cellCurrent: 0, playerHas: .yes) }
        s = compute(grid: grid, dungeonTracker: dt)
        #expect(dt.dungeon(0).isComplete)
        #expect(s.owRouteworthySpots[x, y] == false)
    }

    @Test("dungeon 9 is routeworthy only once every triforce piece is held")
    func dungeon9NeedsAllTriforce() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.dungeon(9), column: x, row: y)
        let dt = DungeonTrackerInstance()

        #expect(compute(grid: grid, dungeonTracker: dt).owRouteworthySpots[x, y] == false)
        // Give 7 of 8 pieces -> still not routeworthy.
        for i in 0..<7 { dt.dungeon(i).toggleTriforce() }
        #expect(compute(grid: grid, dungeonTracker: dt).owRouteworthySpots[x, y] == false)
        dt.dungeon(7).toggleTriforce()
        let s = compute(grid: grid, dungeonTracker: dt)
        #expect(s.dungeonLocations[8] == OverworldScreenCoordinate(x: x, y: y))
        #expect(s.owRouteworthySpots[x, y] == true)
    }

    @Test("magical sword cave: found + located; routeworthy iff no mag-sword and >=10 hearts")
    func swordCave3() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.swordCave(3), column: x, row: y)

        // 3 hearts, no mag sword -> found+located but not routeworthy (need 10 hearts).
        var s = compute(grid: grid, playerState: PlayerComputedStateSummary(playerHearts: 3))
        #expect(s.magsCaveFound)
        #expect(s.sword3Location == OverworldScreenCoordinate(x: x, y: y))
        #expect(s.owRouteworthySpots[x, y] == false)

        // 10 hearts, no mag sword -> routeworthy.
        s = compute(grid: grid, playerState: PlayerComputedStateSummary(playerHearts: 10))
        #expect(s.owRouteworthySpots[x, y] == true)

        // 10 hearts but already has mag sword -> not routeworthy.
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasMagicalSword = true
        s = compute(grid: grid, playerState: PlayerComputedStateSummary(playerHearts: 10), progress: progress)
        #expect(s.owRouteworthySpots[x, y] == false)
    }

    @Test("white sword cave: located; routeworthy iff no WS item and >=4 hearts")
    func swordCave2() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.swordCave(2), column: x, row: y)

        var s = compute(grid: grid, playerState: PlayerComputedStateSummary(playerHearts: 3))
        #expect(s.sword2Location == OverworldScreenCoordinate(x: x, y: y))
        #expect(s.owRouteworthySpots[x, y] == false) // only 3 hearts

        s = compute(grid: grid, playerState: PlayerComputedStateSummary(playerHearts: 4))
        #expect(s.owRouteworthySpots[x, y] == true)

        s = compute(grid: grid, playerState: PlayerComputedStateSummary(haveWhiteSwordItem: true, playerHearts: 4))
        #expect(s.owRouteworthySpots[x, y] == false) // already have it
    }

    @Test("wood sword cave: found + located, no routeworthy rule (reference TODO)")
    func swordCave1() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.swordCave(1), column: x, row: y)
        let s = compute(grid: grid)
        #expect(s.woodSwordCaveFound)
        #expect(s.sword1Location == OverworldScreenCoordinate(x: x, y: y))
        #expect(s.owRouteworthySpots[x, y] == false)
    }

    @Test("armos: located; routeworthy until its box is done")
    func armos() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.armos, column: x, row: y)
        let dt = DungeonTrackerInstance()

        var s = compute(grid: grid, dungeonTracker: dt)
        #expect(s.armosLocation == OverworldScreenCoordinate(x: x, y: y))
        #expect(s.owRouteworthySpots[x, y] == true)

        dt.armosBox.set(cellCurrent: 0, playerHas: .yes) // now done
        s = compute(grid: grid, dungeonTracker: dt)
        #expect(s.owRouteworthySpots[x, y] == false)
    }

    @Test("shop discovery matches primary mark or stored second item")
    func shopDiscovery() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.shop(.blueRing), column: x, row: y)
        #expect(compute(grid: grid).foundBlueRingShop)

        // A 3-item shop whose primary is arrow but second item is blue ring.
        let (x2, y2) = Self.safeScreen2
        let grid2 = OverworldGrid()
        grid2.setMark(.shop(.arrow), column: x2, row: y2)
        grid2.setExtraData(
            OverworldTileMark.toItem(rawIndex: 20), // BLUE_RING -> 5
            column: x2, row: y2, key: OverworldTileMark.shopExtraDataKey)
        let s = compute(grid: grid2)
        #expect(s.foundArrowShop)
        #expect(s.foundBlueRingShop)
        #expect(!s.foundBookShop)
    }

    @Test("potion letter found only when its extra-data toggle is 0")
    func potionLetter() {
        let (x, y) = Self.safeScreen
        let grid = OverworldGrid()
        grid.setMark(.theLetter, column: x, row: y)
        #expect(compute(grid: grid).havePotionLetter)

        grid.setExtraData(30, column: x, row: y, key: 30) // non-zero -> not "have it"
        #expect(compute(grid: grid).havePotionLetter == false)
    }

    @Test("coast item screen [15,5] is routeworthy iff ladder held and item not taken")
    func coastItem() {
        // No ladder -> not routeworthy.
        #expect(compute().owRouteworthySpots[15, 5] == false)
        // Ladder, no coast item -> routeworthy.
        #expect(compute(playerState: PlayerComputedStateSummary(haveLadder: true)).owRouteworthySpots[15, 5] == true)
        // Ladder but already have coast item -> not routeworthy.
        #expect(compute(playerState: PlayerComputedStateSummary(haveLadder: true, haveCoastItem: true)).owRouteworthySpots[15, 5] == false)
    }

    @Test("any-road marks populate anyRoadLocations by warp number — the routing input (T-015.5)")
    func anyRoadLocations() {
        let grid = OverworldGrid()
        let a = Self.safeScreen       // any-road 1
        let b = Self.safeScreen2      // any-road 3
        grid.setMark(.anyRoad(1), column: a.x, row: a.y)
        grid.setMark(.anyRoad(3), column: b.x, row: b.y)

        let s = compute(grid: grid)
        #expect(s.anyRoadLocations[0] == OverworldScreenCoordinate(x: a.x, y: a.y)) // warp 1 -> index 0
        #expect(s.anyRoadLocations[1] == nil)
        #expect(s.anyRoadLocations[2] == OverworldScreenCoordinate(x: b.x, y: b.y)) // warp 3 -> index 2
        #expect(s.anyRoadLocations[3] == nil)

        // This is exactly what OverworldMapView feeds to dynamicGraph(anyRoads:).
        let destinations = s.anyRoadLocations.compactMap { $0 }.map { (x: $0.x, y: $0.y) }
        #expect(destinations.count == 2)
    }

    @Test("coast island [15,2] screen-scroll special case needs draw+scroll+mirror")
    func coastIslandScreenScroll() {
        // Empty-handed the raftable coast-island screen is not routeworthy...
        #expect(compute().owRouteworthySpots[15, 2] == false)
        // ...unless drawRoutes && routesCanScreenScroll && mirrorOverworld all hold.
        let s = compute(drawRoutes: true, routesCanScreenScroll: true, mirrorOverworld: true)
        #expect(s.owRouteworthySpots[15, 2] == true)
        // Any one missing -> still not.
        #expect(compute(drawRoutes: true, routesCanScreenScroll: true, mirrorOverworld: false).owRouteworthySpots[15, 2] == false)
    }
}
