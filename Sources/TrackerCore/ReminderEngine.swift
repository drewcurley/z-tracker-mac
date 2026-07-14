/// One edge-triggered announcement the tracker wants to surface to the
/// player (spoken and/or shown). The value payload of a reference
/// `ITrackerEvents` *announcement* callback. Ported from the announcement
/// members of `ITrackerEvents`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:1486-1508`).
public enum ReminderAnnouncement: Equatable, Sendable {
    /// Hearts crossed 4–6 and the white-sword cave is known but its item
    /// unobtained.
    case considerSword2
    /// Hearts crossed 10–14 and the magical-sword cave is known but the
    /// magical sword unobtained.
    case considerSword3
    /// Dungeon `index` (0–7) just became complete.
    case completedDungeon(Int)
    /// The number of located dungeons just increased to this value.
    case foundDungeonCount(Int)
    /// The number of owned triforce pieces just increased to this value.
    case triforceCount(Int)
    /// The player is probably Triforce-and-Go (level > 101). Carries the
    /// current triforce count and the scored summary.
    case triforceAndGo(triforces: Int, summary: TriforceAndGoSummary)
    /// A newly-acquired item unblocks dungeons the player left blocked on it:
    /// go back. `dungeons` are the 0–7 indices; `combatDetails` is non-empty
    /// only for a `combat` unblock.
    case remindUnblock(blocker: DungeonBlocker, dungeons: [Int], combatDetails: [CombatUnblockerDetail])
    /// A one-shot "you just got this, remember it" nudge for an `ITEMS` id.
    case remindShortly(itemId: Int)
}

/// The edge-triggered reminder/announcement engine. Ported from
/// `allUIEventingLogic(ite)` (`TrackerModel.fs:1568-1750`) plus its
/// transition trackers (`:1509-1530`) and
/// `ResetForGroundhogOrRoutersOrFourPlusFourEtc` (`:1531-1552`).
///
/// **Architecture (grounded in the source + this project's established
/// pattern).** The reference drives a UI-implemented `ITrackerEvents`
/// delegate from a once-per-second poll. Its callbacks are two kinds:
/// - *state-push* (`CurrentHearts`, `OverworldSpotsRemaining`,
///   `DungeonLocation`, `Armos`, `Sword2/3`, `RoutingInfo`,
///   `CompletedDungeons`, …) — idempotent "here is the current value". These
///   are **redundant under `@Observable`**: the views already read the model
///   (`playerComputedStateSummary`, `mapStateSummary`, `dungeonTracker`)
///   directly, so they are not ported as callbacks.
/// - *edge-triggered announcements* — genuinely stateful one-shots gated by
///   `prior*`/`haveAnnounced*` trackers. **This is the real engine**, ported
///   here as `poll(...) -> [ReminderAnnouncement]`: the app calls `poll` on
///   its timer and renders the returned announcements (speech/visual — the
///   rendering surface is T-018.3).
///
/// So the reactive `@Observable` equivalent of `ITrackerEvents` is: views
/// observe the model for state; the app polls this engine for announcements.
/// A literal delegate-protocol port was considered and rejected — it would
/// re-introduce the state-push callbacks that `@Observable` already covers.
///
/// **`HasBeenLocated` simplification:** the reference's `locatedDungeons`
/// uses `GetDungeon(d).HasBeenLocated()` (a dungeon marked on *any* screen)
/// while `numFound` uses `DungeonLocations` (marked on a non-always-empty
/// screen). This port derives both from `mapState.dungeonLocations`; the two
/// differ only if a dungeon is marked on an always-empty screen (a
/// nonsensical action in normal play).
///
/// **Deferred with T-018.3 / other tasks:** the timeline data
/// (`timelineDataOverworldSpotsRemain`, a timeline-UI feature) and
/// recorder-warp-destination derivation (a routing concern deferred from
/// T-015.5, only fed the dropped `RoutingInfo` state-push).
public final class ReminderEngine {
    // Transition trackers (`TrackerModel.fs:1509-1530`).
    private var haveAnnouncedHearts = Array(repeating: false, count: 17)
    private var haveAnnouncedCompletedDungeons = Array(repeating: false, count: 8)
    private var previouslyAnnouncedFoundDungeonCount = 0
    private var previouslyAnnouncedTriforceCount = 0
    private var previouslyLocatedDungeonCount = 0
    private var remindedLadder = false
    private var remindedAnyKey = false
    private var priorSwordLevel = 0
    private var priorSwordWandLevel = 0
    private var priorRingLevel = 0
    private var priorBombs = false
    private var priorBowArrow = false
    private var priorRecorder = false
    private var priorLadder = false
    private var priorAnyKey = false
    private var previouslyAnnouncedTriforceAndGo = 0
    private var previousCompletedDungeonCount = 0

    public init() {}

    /// Full-state reset for a "restart run" (groundhog/routers) feature.
    /// Ported from `ResetForGroundhogOrRoutersOrFourPlusFourEtc`
    /// (`TrackerModel.fs:1531-1552`) — note the reference deliberately does
    /// **not** reset `previouslyAnnouncedFoundDungeonCount`,
    /// `previouslyLocatedDungeonCount`, `priorBombs`, or `priorOWSpotsRemain`
    /// (those still hold across a restart).
    public func resetForGroundhogOrRouters() {
        for i in haveAnnouncedHearts.indices { haveAnnouncedHearts[i] = false }
        for i in haveAnnouncedCompletedDungeons.indices { haveAnnouncedCompletedDungeons[i] = false }
        previouslyAnnouncedTriforceCount = 0
        remindedLadder = false
        remindedAnyKey = false
        priorSwordLevel = 0
        priorSwordWandLevel = 0
        priorRingLevel = 0
        priorBowArrow = false
        priorRecorder = false
        priorLadder = false
        priorAnyKey = false
        previouslyAnnouncedTriforceAndGo = 0
        previousCompletedDungeonCount = 0
    }

    /// Diffs current-vs-remembered state and returns the announcements to
    /// fire this tick, mutating the trackers. A structure-preserving port of
    /// `allUIEventingLogic` (`TrackerModel.fs:1568-1750`) minus the
    /// state-push callbacks (see the type doc). `tagSummary` is passed in
    /// (the caller has the grid/instance it needs — see `TriforceAndGoSummary`).
    public func poll(
        playerState: PlayerComputedStateSummary,
        mapState: MapStateSummary,
        dungeonTracker: DungeonTrackerInstance,
        blockers: DungeonBlockersContainer,
        progress: PlayerProgressAndTakeAnyHearts,
        startingItems: StartingItemsAndExtras,
        tagSummary: TriforceAndGoSummary
    ) -> [ReminderAnnouncement] {
        var out: [ReminderAnnouncement] = []

        // hearts (`:1571-1581`)
        let playerHearts = playerState.playerHearts
        if playerHearts >= 4, playerHearts <= 6, !haveAnnouncedHearts[playerHearts] {
            haveAnnouncedHearts[playerHearts] = true
            if !playerState.haveWhiteSwordItem && mapState.sword2Location != nil {
                out.append(.considerSword2)
            }
        }
        if playerHearts >= 10, playerHearts <= 14, !haveAnnouncedHearts[playerHearts] {
            haveAnnouncedHearts[playerHearts] = true
            if !progress.hasMagicalSword && mapState.sword3Location != nil {
                out.append(.considerSword3)
            }
        }

        // dungeon completion + found count (`:1626-1637`)
        for d in 0...7 where !haveAnnouncedCompletedDungeons[d] && dungeonTracker.dungeon(d).isComplete {
            out.append(.completedDungeon(d))
            haveAnnouncedCompletedDungeons[d] = true
        }
        let numFound = (0...8).reduce(0) { $0 + (mapState.dungeonLocations[$1] != nil ? 1 : 0) }
        if numFound > previouslyAnnouncedFoundDungeonCount {
            out.append(.foundDungeonCount(numFound))
            previouslyAnnouncedFoundDungeonCount = numFound
        }

        // triforce count + Triforce-and-Go (`:1638-1667`)
        let triforces = dungeonTracker
            .getTriforceHaves(hdnStartingTriforcePieces: startingItems.hdnStartingTriforcePieces)
            .lazy.filter { $0 }.count
        let locatedDungeons = numFound // see HasBeenLocated note in the type doc
        let completedDungeons = (0...8).reduce(0) { $0 + (dungeonTracker.dungeon($1).isComplete ? 1 : 0) }
        var justAnnouncedTAG = false
        if triforces > previouslyAnnouncedTriforceCount {
            out.append(.triforceCount(triforces))
            previouslyAnnouncedTriforceCount = triforces
            if completedDungeons <= previousCompletedDungeonCount && tagSummary.level > 101 {
                out.append(.triforceAndGo(triforces: triforces, summary: tagSummary))
                justAnnouncedTAG = true
            }
        }
        if locatedDungeons > previouslyLocatedDungeonCount && tagSummary.level > 101 && !justAnnouncedTAG {
            out.append(.triforceAndGo(triforces: triforces, summary: tagSummary))
            justAnnouncedTAG = true
        }
        previousCompletedDungeonCount = completedDungeons
        previouslyLocatedDungeonCount = locatedDungeons
        if tagSummary.level > previouslyAnnouncedTriforceAndGo {
            previouslyAnnouncedTriforceAndGo = tagSummary.level
            if !justAnnouncedTAG {
                out.append(.triforceAndGo(triforces: triforces, summary: tagSummary))
            }
        }

        // combat blockers (`:1668-1701`)
        func calcFromDungeon(_ item: Int) -> Int {
            var fromDungeon = -1
            for i in 0...7 where dungeonTracker.dungeon(i).boxes.contains(where: { $0.cellCurrent == item }) {
                fromDungeon = i
            }
            return fromDungeon
        }
        var combatUnblockers: [CombatUnblockerDetail] = []
        var combatUnblockerOrigins: [Int] = []
        if playerState.swordLevel > priorSwordWandLevel
            || (playerState.swordLevel >= 2 && priorSwordLevel < 2) {
            combatUnblockers.append(.betterSword)
            if playerState.swordLevel == 2 {
                combatUnblockerOrigins.append(calcFromDungeon(ITEMS.whiteSword))
            }
        }
        if playerState.haveWand && priorSwordWandLevel < 2 {
            combatUnblockers.append(.wand)
            combatUnblockerOrigins.append(calcFromDungeon(ITEMS.wand))
        }
        if playerState.ringLevel > priorRingLevel
            && (playerState.swordLevel > 0 || playerState.haveWand) {
            combatUnblockers.append(.betterArmor)
            combatUnblockerOrigins.append(calcFromDungeon(ITEMS.redRing))
        }
        if !combatUnblockers.isEmpty {
            var dungeonIdxs: [Int] = []
            for i in 0...7 {
                if combatUnblockerOrigins.count == 1 && combatUnblockerOrigins[0] == i {
                    continue // already in the dungeon we'd remind them to go to
                }
                let anyCombatBlocker = (0..<DungeonBlockersContainer.maxBlockersPerDungeon)
                    .contains { blockers.dungeonBlocker(dungeon: i, slot: $0) == .combat }
                if anyCombatBlocker && !dungeonTracker.dungeon(i).isComplete {
                    dungeonIdxs.append(i)
                }
            }
            if !dungeonIdxs.isEmpty && tagSummary.level < 103 {
                out.append(.remindUnblock(blocker: .combat, dungeons: dungeonIdxs, combatDetails: combatUnblockers))
            }
        }
        priorSwordLevel = playerState.swordLevel
        priorSwordWandLevel = max(playerState.swordLevel, playerState.haveWand ? 2 : 0)
        priorRingLevel = playerState.ringLevel

        // generic blockers (`:1702-1735`)
        func blockerLogic(_ db: DungeonBlocker, fromDungeon: Int) {
            var dungeonIdxs: [Int] = []
            for i in 0...7 where i != fromDungeon {
                let anyMatching = (0..<DungeonBlockersContainer.maxBlockersPerDungeon)
                    .contains { blockers.dungeonBlocker(dungeon: i, slot: $0).hardCanonical == db.hardCanonical }
                if anyMatching && !dungeonTracker.dungeon(i).isComplete {
                    dungeonIdxs.append(i)
                }
            }
            if !dungeonIdxs.isEmpty && tagSummary.level < 103 {
                out.append(.remindUnblock(blocker: db, dungeons: dungeonIdxs, combatDetails: []))
            }
        }
        if !priorBombs && progress.hasBombs { blockerLogic(.bomb, fromDungeon: -1) }
        priorBombs = progress.hasBombs
        if !priorBowArrow && playerState.haveBow && playerState.arrowLevel >= 1 {
            blockerLogic(.bowAndArrow, fromDungeon: calcFromDungeon(ITEMS.bow))
        }
        priorBowArrow = playerState.haveBow && playerState.arrowLevel >= 1
        if !priorRecorder && playerState.haveRecorder {
            blockerLogic(.recorder, fromDungeon: calcFromDungeon(ITEMS.recorder))
        }
        priorRecorder = playerState.haveRecorder
        if !priorLadder && playerState.haveLadder {
            blockerLogic(.ladder, fromDungeon: calcFromDungeon(ITEMS.ladder))
        }
        priorLadder = playerState.haveLadder
        if !priorAnyKey && playerState.haveAnyKey {
            blockerLogic(.key, fromDungeon: calcFromDungeon(ITEMS.anyKey))
        }
        priorAnyKey = playerState.haveAnyKey

        // one-shot item nudges (`:1738-1744`)
        if !remindedLadder && playerState.haveLadder {
            out.append(.remindShortly(itemId: ITEMS.ladder))
            remindedLadder = true
        }
        if !remindedAnyKey && playerState.haveAnyKey {
            out.append(.remindShortly(itemId: ITEMS.anyKey))
            remindedAnyKey = true
        }

        return out
    }
}
