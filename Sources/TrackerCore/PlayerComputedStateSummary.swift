/// The central "derived player state" — everything routing, GYR, reminders,
/// and the item tracker actually read, recomputed from the player-state
/// foundation (`StartingItemsAndExtras` + `PlayerProgressAndTakeAnyHearts`,
/// T-012) and the dungeon boxes (`DungeonTrackerInstance.allBoxes()`,
/// T-013). Ported from the reference's `PlayerComputedStateSummary`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:841-861`) and
/// its `recomputePlayerStateSummary()` (`:865-958`).
///
/// **`@Observable`-computed instead of mutable-global-plus-recompute.** The
/// reference holds a mutable global `playerComputedStateSummary` and calls
/// `recomputePlayerStateSummary()` on a poll / change events. This port
/// makes the summary an immutable value derived on demand by
/// `compute(...)`; because it reads only `@Observable` inputs, any SwiftUI
/// view that reads it re-derives automatically when a box/starting-item/
/// progress flag changes — the same pattern `Dungeon.isComplete` uses. The
/// reference's `LastChangedTime` / `playerComputedStateSummaryForPlayerHas-
/// BookChanged` event and the `playerSwordLevel`/`…` mirror `EventingInt`s
/// are notification plumbing with no T-014 consumer and are not ported.
public struct PlayerComputedStateSummary: Equatable, Sendable {
    public let haveRecorder: Bool
    public let haveLadder: Bool
    public let haveAnyKey: Bool
    public let haveCoastItem: Bool
    public let haveWhiteSwordItem: Bool
    public let havePowerBracelet: Bool
    public let haveRaft: Bool
    public let playerHearts: Int
    /// 0…3
    public let swordLevel: Int
    /// 0…2
    public let candleLevel: Int
    /// 0…2
    public let ringLevel: Int
    public let haveBow: Bool
    /// 0…2
    public let arrowLevel: Int
    public let haveWand: Bool
    public let haveBookOrShield: Bool
    /// 0…2
    public let boomerangLevel: Int

    public init(
        haveRecorder: Bool = false,
        haveLadder: Bool = false,
        haveAnyKey: Bool = false,
        haveCoastItem: Bool = false,
        haveWhiteSwordItem: Bool = false,
        havePowerBracelet: Bool = false,
        haveRaft: Bool = false,
        playerHearts: Int = 3,
        swordLevel: Int = 0,
        candleLevel: Int = 0,
        ringLevel: Int = 0,
        haveBow: Bool = false,
        arrowLevel: Int = 0,
        haveWand: Bool = false,
        haveBookOrShield: Bool = false,
        boomerangLevel: Int = 0
    ) {
        self.haveRecorder = haveRecorder
        self.haveLadder = haveLadder
        self.haveAnyKey = haveAnyKey
        self.haveCoastItem = haveCoastItem
        self.haveWhiteSwordItem = haveWhiteSwordItem
        self.havePowerBracelet = havePowerBracelet
        self.haveRaft = haveRaft
        self.playerHearts = playerHearts
        self.swordLevel = swordLevel
        self.candleLevel = candleLevel
        self.ringLevel = ringLevel
        self.haveBow = haveBow
        self.arrowLevel = arrowLevel
        self.haveWand = haveWand
        self.haveBookOrShield = haveBookOrShield
        self.boomerangLevel = boomerangLevel
    }

    /// Recomputes the summary from current state. A faithful, structure-
    /// preserving port of `recomputePlayerStateSummary()`
    /// (`TrackerModel.fs:865-958`): scan every box for `.yes` cells matching
    /// specific `ITEMS.*` ids, then layer in progress flags, then starting
    /// items, then the two standalone-box "done" checks, then hearts.
    ///
    /// **The only seed-option flag the recompute branches on is
    /// `isWSMSReplacedByBU`** — verified against the source, which reads
    /// `IsWSMSReplacedByBU()` (twice) and does *not* reference
    /// `IsCurrentlyBook`/`IsBookAnAtlas` here (those gate `PlayerHasTheBook`
    /// / `PlayerCanSeeMapOfThisDungeon`, deferred with their own consumers).
    /// When on, the White-Sword item box and the Magical-Sword starting item
    /// are Bomb-Upgrade slots instead, so they don't raise the sword level
    /// (`TrackerModel.fs:911, 924`).
    public static func compute(
        dungeonTracker: DungeonTrackerInstance,
        startingItems: StartingItemsAndExtras,
        progress: PlayerProgressAndTakeAnyHearts,
        isWSMSReplacedByBU: Bool
    ) -> PlayerComputedStateSummary {
        var haveRecorder = false
        var haveLadder = false
        var haveAnyKey = false
        var haveCoastItem = false
        var haveWhiteSwordItem = false
        var havePowerBracelet = false
        var haveRaft = false
        var playerHearts = 3
        var swordLevel = 0
        var candleLevel = 0
        var ringLevel = 0
        var haveBow = false
        var arrowLevel = 0
        var haveWand = false
        var haveBookOrShield = false
        var boomerangLevel = 0

        // Scan the boxes for obtained (`.yes`) items. Order and predicates
        // mirror `TrackerModel.fs:872-912` exactly.
        for box in dungeonTracker.allBoxes() where box.playerHas == .yes {
            switch box.cellCurrent {
            case ITEMS.recorder: haveRecorder = true
            case ITEMS.ladder: haveLadder = true
            case ITEMS.anyKey: haveAnyKey = true
            case ITEMS.powerBracelet: havePowerBracelet = true
            case ITEMS.raft: haveRaft = true
            case ITEMS.redCandle: candleLevel = 2
            case ITEMS.heartContainer: playerHearts += 1
            case ITEMS.bookOrShield: haveBookOrShield = true
            case ITEMS.boomerang: boomerangLevel = max(boomerangLevel, 1)
            case ITEMS.bow: haveBow = true
            case ITEMS.magicBoomerang: boomerangLevel = 2
            case ITEMS.redRing: ringLevel = 2
            case ITEMS.silverArrow: arrowLevel = 2
            case ITEMS.wand: haveWand = true
            case ITEMS.whiteSword:
                if !isWSMSReplacedByBU { swordLevel = max(swordLevel, 2) }
            default: break
            }
        }

        // Progress flags (`:913-922`).
        if progress.hasBlueCandle { candleLevel = max(candleLevel, 1) }
        if progress.hasMagicalSword && !isWSMSReplacedByBU { swordLevel = 3 }
        if progress.hasWoodSword { swordLevel = max(swordLevel, 1) }
        if progress.hasBlueRing { ringLevel = max(ringLevel, 1) }
        if progress.hasWoodArrow { arrowLevel = max(arrowLevel, 1) }

        // Starting items (`:923-948`).
        if startingItems.hasWhiteSword { swordLevel = max(swordLevel, 2) }
        if startingItems.hasMagicalSword { swordLevel = 3 }
        if startingItems.hasSilverArrow { arrowLevel = 2 }
        if startingItems.hasBoomerang { boomerangLevel = max(boomerangLevel, 1) }
        if startingItems.hasMagicBoomerang { boomerangLevel = 2 }
        if startingItems.hasBow { haveBow = true }
        if startingItems.hasRedCandle { candleLevel = 2 }
        if startingItems.hasWand { haveWand = true }
        if startingItems.hasRedRing { ringLevel = 2 }
        if startingItems.hasPowerBracelet { havePowerBracelet = true }
        if startingItems.hasLadder { haveLadder = true }
        if startingItems.hasRaft { haveRaft = true }
        if startingItems.hasRecorder { haveRecorder = true }
        if startingItems.hasAnyKey { haveAnyKey = true }
        if startingItems.hasBook { haveBookOrShield = true }

        // Standalone boxes (`:949-952`): coast item and white-sword-cave item
        // are "done" checks, not item-id scans.
        if dungeonTracker.ladderBox.isDone { haveCoastItem = true }
        if dungeonTracker.sword2Box.isDone { haveWhiteSwordItem = true }

        // Hearts from Take-Any caves + the starting differential (`:953-956`).
        for h in 0..<4 where progress.takeAnyHearts[h] == .takenHeart {
            playerHearts += 1
        }
        playerHearts += startingItems.maxHeartsDifferential

        return PlayerComputedStateSummary(
            haveRecorder: haveRecorder,
            haveLadder: haveLadder,
            haveAnyKey: haveAnyKey,
            haveCoastItem: haveCoastItem,
            haveWhiteSwordItem: haveWhiteSwordItem,
            havePowerBracelet: havePowerBracelet,
            haveRaft: haveRaft,
            playerHearts: playerHearts,
            swordLevel: swordLevel,
            candleLevel: candleLevel,
            ringLevel: ringLevel,
            haveBow: haveBow,
            arrowLevel: arrowLevel,
            haveWand: haveWand,
            haveBookOrShield: haveBookOrShield,
            boomerangLevel: boomerangLevel
        )
    }
}
