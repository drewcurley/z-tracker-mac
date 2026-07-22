/// A 16×8 grid of booleans over the overworld screens, the Swift analog of
/// the reference's `Array2D.zeroCreate 16 8` bool arrays. Indexed `[x, y]`
/// (`x` = column `0…15`, `y` = row `0…7`) exactly as the reference's
/// `arr.[i,j]`.
public struct ScreenBoolGrid: Sendable, Equatable {
    private var values: [Bool]

    public init() {
        values = Array(repeating: false, count: 16 * 8)
    }

    public subscript(x: Int, y: Int) -> Bool {
        get {
            precondition((0..<16).contains(x) && (0..<8).contains(y), "(\(x),\(y)) out of 16×8")
            return values[x * 8 + y]
        }
        set {
            precondition((0..<16).contains(x) && (0..<8).contains(y), "(\(x),\(y)) out of 16×8")
            values[x * 8 + y] = newValue
        }
    }

    /// Total `true` cells — handy for scenario assertions.
    public var trueCount: Int { values.lazy.filter { $0 }.count }
}

/// The derived overworld-map state: where each dungeon / any-road / sword
/// cave / armos is located, which unmarked screens are *gettable* (the red
/// GYR input) and *routeworthy* (worth routing to), how many spots remain,
/// and the eight shop/cave-discovery flags. Ported from the reference's
/// `MapStateSummary` type (`TrackerModel.fs:1015-1030`) and
/// `recomputeMapStateSummary()` (`:1032-1143`).
///
/// **`@Observable`-computed instead of a mutable global + recompute.** Like
/// `PlayerComputedStateSummary` (T-014), this is an immutable value derived
/// on demand by `compute(...)` from `@Observable` inputs, replacing the
/// reference's mutable `mapStateSummary` global, its `recomputeMapState-
/// Summary()`, the `LastChangedTime`, and the eight module-level
/// `EventingBool` discovery flags (folded in here as plain fields).
public struct MapStateSummary: Sendable {
    /// Located dungeon screens, index `0…8` for dungeons 1–9; `nil` = not yet
    /// located (the reference's `NOTFOUND = (-1,-1)`).
    public let dungeonLocations: [OverworldScreenCoordinate?]
    /// Located any-road (warp) screens, index `0…3`; `nil` = not located.
    public let anyRoadLocations: [OverworldScreenCoordinate?]
    public let armosLocation: OverworldScreenCoordinate?
    public let sword3Location: OverworldScreenCoordinate?
    public let sword2Location: OverworldScreenCoordinate?
    public let sword1Location: OverworldScreenCoordinate?
    /// How many overworld spots still hold an unknown thing.
    public let owSpotsRemain: Int
    /// The screens the player can currently *reach and uncover* — the red/
    /// not-red GYR input consumed by `doComputedDrawing` (T-015.4).
    public let owGettableLocations: ScreenBoolGrid
    /// Unmarked screens reachable by playing the recorder.
    public let owWhistleSpotsRemain: [OverworldScreenCoordinate]
    /// Count of unmarked screens uncoverable by pushing with the bracelet.
    public let owPowerBraceletSpotsRemain: Int
    /// Screens worth routing to (reachable-and-useful).
    public let owRouteworthySpots: ScreenBoolGrid
    /// For MIXED-quest dimming: interesting marks on first-quest-only screens.
    public let firstQuestOnlyInterestingMarks: ScreenBoolGrid
    /// For MIXED-quest dimming: interesting marks on second-quest-only screens.
    public let secondQuestOnlyInterestingMarks: ScreenBoolGrid

    // The eight shop/cave-discovery flags (`TrackerModel.fs:1013`).
    public let magsCaveFound: Bool
    public let woodSwordCaveFound: Bool
    public let foundBlueRingShop: Bool
    public let foundBookShop: Bool
    public let foundCandleShop: Bool
    public let foundArrowShop: Bool
    public let foundBombShop: Bool
    public let havePotionLetter: Bool

    /// Recomputes the summary. A structure-preserving port of
    /// `recomputeMapStateSummary()` (`TrackerModel.fs:1032-1143`): iterate
    /// every non-always-empty screen, classify by its mark's raw index, and
    /// accumulate locations / gettable / routeworthy / discovery state, then
    /// apply the coast-item routeworthy rule. All the external state the
    /// reference reads from globals is passed explicitly here.
    ///
    /// - Parameters:
    ///   - drawRoutes/routesCanScreenScroll/mirrorOverworld: the three option
    ///     flags the single coast-island screen-scroll special case
    ///     (`:1119`) reads. `mirrorOverworld` has no live source until
    ///     T-015.5; callers pass `false` until then.
    public static func compute(
        grid: OverworldGrid,
        instance: OverworldInstance,
        dungeonTracker: DungeonTrackerInstance,
        playerState: PlayerComputedStateSummary,
        progress: PlayerProgressAndTakeAnyHearts,
        drawRoutes: Bool,
        routesCanScreenScroll: Bool,
        mirrorOverworld: Bool,
        /// A custom overworld map (T-167) has no quest-derived dead spots, so every
        /// screen counts toward the spots-remaining total.
        customMapActive: Bool = false
    ) -> MapStateSummary {
        var dungeonLocations = [OverworldScreenCoordinate?](repeating: nil, count: 9)
        var anyRoadLocations = [OverworldScreenCoordinate?](repeating: nil, count: 4)
        var armosLocation: OverworldScreenCoordinate?
        var sword3Location: OverworldScreenCoordinate?
        var sword2Location: OverworldScreenCoordinate?
        var sword1Location: OverworldScreenCoordinate?
        var owSpotsRemain = 0
        var owGettableLocations = ScreenBoolGrid()
        var owWhistleSpotsRemain: [OverworldScreenCoordinate] = []
        var owPowerBraceletSpotsRemain = 0
        var owRouteworthySpots = ScreenBoolGrid()
        var firstQuestOnlyInterestingMarks = ScreenBoolGrid()
        var secondQuestOnlyInterestingMarks = ScreenBoolGrid()
        var magsCaveFound = false
        var woodSwordCaveFound = false
        var foundBlueRingShop = false
        var foundBookShop = false
        var foundCandleShop = false
        var foundArrowShop = false
        var foundBombShop = false
        var havePotionLetter = false

        for i in 0..<16 {
            for j in 0..<8 {
                if !customMapActive, instance.alwaysEmpty(x: i, y: j) { continue }
                let cur = grid.mark(column: i, row: j).rawIndex
                switch cur {
                case 0...8: // dungeon 1-9
                    dungeonLocations[cur] = OverworldScreenCoordinate(x: i, y: j)
                    if cur < 8 && !dungeonTracker.dungeon(cur).isComplete {
                        owRouteworthySpots[i, j] = true
                    }
                    let playerHasAllTriforce = (0...7).allSatisfy {
                        dungeonTracker.dungeon($0).playerHasTriforce
                    }
                    if cur == 8 && playerHasAllTriforce {
                        owRouteworthySpots[i, j] = true
                    }
                case 9...12: // any-road / warp 1-4
                    anyRoadLocations[cur - 9] = OverworldScreenCoordinate(x: i, y: j)
                case 13: // SWORD3 (magical sword cave)
                    magsCaveFound = true
                    sword3Location = OverworldScreenCoordinate(x: i, y: j)
                    if !progress.hasMagicalSword && playerState.playerHearts >= 10 {
                        owRouteworthySpots[i, j] = true
                    }
                case 14: // SWORD2 (white sword cave)
                    sword2Location = OverworldScreenCoordinate(x: i, y: j)
                    if !playerState.haveWhiteSwordItem && playerState.playerHearts >= 4 {
                        owRouteworthySpots[i, j] = true
                    }
                case 15: // SWORD1 (wood sword cave)
                    // Reference TODO (`:1071`): "if not took item, is routeworthy" —
                    // unimplemented there, so unimplemented here.
                    woodSwordCaveFound = true
                    sword1Location = OverworldScreenCoordinate(x: i, y: j)
                case 31: // ARMOS
                    armosLocation = OverworldScreenCoordinate(x: i, y: j)
                    if !dungeonTracker.armosBox.isDone {
                        owRouteworthySpots[i, j] = true
                    }
                case -1: // unmarked / empty spot
                    owSpotsRemain += 1
                    if instance.whistleable(x: i, y: j) {
                        owWhistleSpotsRemain.append(OverworldScreenCoordinate(x: i, y: j))
                    }
                    if instance.powerBraceletable(x: i, y: j) {
                        owPowerBraceletSpotsRemain += 1
                    }
                    let cannotUncover =
                        (instance.whistleable(x: i, y: j) && !playerState.haveRecorder)
                        || (instance.powerBraceletable(x: i, y: j) && !playerState.havePowerBracelet)
                        || (instance.ladderable(x: i, y: j) && !playerState.haveLadder)
                        || (instance.raftable(x: i, y: j) && !playerState.haveRaft)
                        || (instance.bombable(x: i, y: j) && !progress.hasBombs)
                        || (instance.burnable(x: i, y: j) && playerState.candleLevel == 0)
                    if cannotUncover {
                        // Player can't uncover the spot... except the coast island,
                        // reachable out-of-logic by screen-scrolling when mirrored
                        // (`:1119`) — worth teaching that it's possible.
                        if i == 15 && j == 2 && drawRoutes && routesCanScreenScroll && mirrorOverworld {
                            owRouteworthySpots[i, j] = true
                        }
                    } else {
                        owRouteworthySpots[i, j] = true
                        owGettableLocations[i, j] = true
                    }
                case OverworldTileMark.maxRawIndex: // DARK_X (35)
                    if grid.extraData(column: i, row: j, key: OverworldTileMark.maxRawIndex)
                        == OverworldTileMark.maxRawIndex {
                        owSpotsRemain += 1 // un-revealed dark spots count as remaining
                    }
                default:
                    if OverworldTileMark.isItem(rawIndex: cur) { // an item shop
                        let shopItem = grid.extraData(
                            column: i, row: j, key: OverworldTileMark.shopExtraDataKey)
                        // Primary mark OR the stored second item marks the shop found.
                        if cur == 20 || shopItem == OverworldTileMark.toItem(rawIndex: 20) { foundBlueRingShop = true }
                        if cur == 18 || shopItem == OverworldTileMark.toItem(rawIndex: 18) { foundBookShop = true }
                        if cur == 19 || shopItem == OverworldTileMark.toItem(rawIndex: 19) { foundCandleShop = true }
                        if cur == 16 || shopItem == OverworldTileMark.toItem(rawIndex: 16) { foundArrowShop = true }
                        if cur == 17 || shopItem == OverworldTileMark.toItem(rawIndex: 17) { foundBombShop = true }
                    } else if cur == 30 // THE_LETTER
                        && grid.extraData(column: i, row: j, key: 30) == 0 {
                        havePotionLetter = true
                    }
                }

                // Runs for every non-always-empty screen (`:1122-1127`).
                let isInteresting = cur != -1 && cur != OverworldTileMark.maxRawIndex
                if Masks.secondQuestOnly.isX(i, j) {
                    secondQuestOnlyInterestingMarks[i, j] = isInteresting
                }
                if Masks.firstQuestOnly.isX(i, j) {
                    firstQuestOnlyInterestingMarks[i, j] = isInteresting
                }
            }
        }

        // Gettable coast item is routeworthy (`:1129`).
        owRouteworthySpots[15, 5] = playerState.haveLadder && !playerState.haveCoastItem

        return MapStateSummary(
            dungeonLocations: dungeonLocations,
            anyRoadLocations: anyRoadLocations,
            armosLocation: armosLocation,
            sword3Location: sword3Location,
            sword2Location: sword2Location,
            sword1Location: sword1Location,
            owSpotsRemain: owSpotsRemain,
            owGettableLocations: owGettableLocations,
            owWhistleSpotsRemain: owWhistleSpotsRemain,
            owPowerBraceletSpotsRemain: owPowerBraceletSpotsRemain,
            owRouteworthySpots: owRouteworthySpots,
            firstQuestOnlyInterestingMarks: firstQuestOnlyInterestingMarks,
            secondQuestOnlyInterestingMarks: secondQuestOnlyInterestingMarks,
            magsCaveFound: magsCaveFound,
            woodSwordCaveFound: woodSwordCaveFound,
            foundBlueRingShop: foundBlueRingShop,
            foundBookShop: foundBookShop,
            foundCandleShop: foundCandleShop,
            foundArrowShop: foundArrowShop,
            foundBombShop: foundBombShop,
            havePotionLetter: havePotionLetter
        )
    }
}
