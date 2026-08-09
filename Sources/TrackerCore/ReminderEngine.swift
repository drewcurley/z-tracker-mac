import Foundation

/// One edge-triggered announcement the tracker wants to surface to the
/// player (spoken and/or shown). The value payload of a reference
/// `ITrackerEvents` *announcement* callback. Ported from the announcement
/// members of `ITrackerEvents`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:1486-1508`).
public enum ReminderAnnouncement: Equatable, Sendable {
    /// Hearts reached 4–5 and the white-sword cave is known but its item
    /// unobtained — a soft "you're getting close" nudge (T-185).
    case considerSword2
    /// Hearts reached 6 (first time) and the white-sword cave is known but its item
    /// unobtained — the stronger "go get it now" nudge (T-185, user request).
    case getSword2
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
    /// The number of door-repair charges marked on the overworld just increased
    /// to `found` (of `max` for the quest). Ported from the reference's door-repair
    /// reminder (`Z1R_WPF/Reminders.fs:244-250`).
    case doorRepairCount(found: Int, max: Int)
    // Periodic reminders (T-089), ported from `Z1R_WPF/Reminders.fs:193-243`.
    /// Periodic nudge to grab the coast item with the ladder. `itemName` is the
    /// known item's spoken name, or `nil` when the coast item is still unknown.
    case getCoastItem(itemName: String?)
    /// Periodic nudge to grab the armos item while it's located but unobtained (T-185,
    /// user request). `itemName` is the known item's spoken name, or `nil` if unknown.
    case getArmosItem(itemName: String?)
    /// Periodic nudge to buy the boomstick book — only in a boomstick seed (the
    /// Boomstick flag is on) when you have the wand, no book yet, and a book shop is
    /// marked.
    case considerBoomstickBook
    /// One-shot: you just got the Book and this seed's Book grants hints, so go
    /// visit the hint NPCs (T-092, user request — fires only when the
    /// "Book for Helpful Hints" flag is on).
    case remindVisitHints
    /// You destructively changed an overworld mark, e.g. "C4 from door repair to
    /// money making game" (T-096) — a safety net in case it was accidental.
    /// Ported from the reference's `RemindOverworldOverwrites` (`Reminders.fs:130`).
    case overworldOverwrite(coordLabel: String, from: String, to: String)
    /// The number of a money-secret size still to find crossed 1 (one left) or 0
    /// (none left) — T-105 (beyond the reference), so you don't over-mark.
    case secretsRemaining(size: SecretSize, remaining: Int)
}

/// Builds the overworld-overwrite reminder (T-096) for a destructive change of an
/// overworld mark, or `nil` when the change isn't reportable. Ported from
/// `RemindOverworldOverwrites` (`Z1R_WPF/Reminders.fs:130-146`): only fires when
/// the **old** mark was a real mark (not unmarked / don't-care) and it actually
/// changed — skipping the reasonable refinement of an *unknown* secret into a
/// sized secret.
public enum OverworldOverwriteReminder {
    public static func announcement(
        old: OverworldTileMark, new: OverworldTileMark, coordLabel: String
    ) -> ReminderAnnouncement? {
        guard old != new else { return nil }
        // Original must have been a real mark (the reference's DARK_X / -1 guard).
        guard old != .unmarked, old != .dontCare else { return nil }
        // Refining an unknown secret into a sized one isn't destructive — skip.
        if case .secret(.unknown) = old, case .secret(let sz) = new, sz != .unknown {
            return nil
        }
        return .overworldOverwrite(coordLabel: coordLabel,
                                   from: old.displayName, to: new.displayName)
    }
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
    private var remindedRecorder = false
    private var remindedPowerBracelet = false
    private var remindedBookHints = false
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
    private var previouslyAnnouncedDoorRepairCount = 0
    /// Last-seen remaining count per money-secret size (T-105), so a crossing to
    /// 1 (one left) or 0 (none left) fires once. Not reset on groundhog — secret
    /// marks are permanent overworld knowledge.
    private var lastSecretRemaining: [SecretSize: Int] = [:]
    // Periodic-reminder cooldowns (T-089): last time each fired, `nil` = never
    // (so the first eligible poll fires it). The recorder/power-bracelet *spot
    // count* reminders were removed (T-095): they nagged every 5 min and the count
    // was wrong — replaced by one-shot "you have the recorder/power bracelet" nudges.
    private var lastCoastReminder: Date?
    private var lastArmosReminder: Date?
    private var lastBoomstickReminder: Date?

    public init() {}

    /// Whether `interval` minutes have passed since `last` (or it never fired).
    private func cooldownElapsed(_ now: Date, _ last: Date?, minutes: Double) -> Bool {
        guard let last else { return true }
        return now.timeIntervalSince(last) >= minutes * 60
    }

    /// A one-shot "don't forget you have X" nudge that re-arms when the item is
    /// unmarked (T-095), so re-marking fires it again.
    private func itemNudge(_ id: Int, have: Bool, reminded: inout Bool, into out: inout [ReminderAnnouncement]) {
        if have {
            if !reminded { out.append(.remindShortly(itemId: id)); reminded = true }
        } else {
            reminded = false
        }
    }

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
        remindedRecorder = false
        remindedPowerBracelet = false
        remindedBookHints = false
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
        tagSummary: TriforceAndGoSummary,
        doorRepairFound: Int = 0,
        doorRepairMax: Int = 0,
        now: Date = .distantPast,
        coastItemValue: Int = -1,
        isCurrentlyBook: Bool = true,
        bookShopMarked: Bool = false,
        bookForHelpfulHints: Bool = false,
        secretRemaining: [SecretSize: Int] = [:]
    ) -> [ReminderAnnouncement] {
        var out: [ReminderAnnouncement] = []

        // hearts (`:1571-1581`). Re-arm any level above the current heart count so
        // dropping then regaining hearts re-fires (T-095, unmark→remark).
        let playerHearts = playerState.playerHearts
        for n in haveAnnouncedHearts.indices where n > playerHearts { haveAnnouncedHearts[n] = false }
        let needWhiteSwordItem = !playerState.haveWhiteSwordItem && mapState.sword2Location != nil
        // Two-tier white-sword-item nudge (T-185, user request): "consider" at 4–5
        // hearts, then a stronger "get it now" **once** on first reaching 6+. Slot 6 is
        // the once-guard; the re-arm loop above clears it if hearts drop below 6.
        if playerHearts >= 4, playerHearts <= 5, !haveAnnouncedHearts[playerHearts] {
            haveAnnouncedHearts[playerHearts] = true
            if needWhiteSwordItem { out.append(.considerSword2) }
        }
        if playerHearts >= 6, !haveAnnouncedHearts[6] {
            haveAnnouncedHearts[6] = true
            if needWhiteSwordItem { out.append(.getSword2) }
        }
        if playerHearts >= 10, playerHearts <= 14, !haveAnnouncedHearts[playerHearts] {
            haveAnnouncedHearts[playerHearts] = true
            if !progress.hasMagicalSword && mapState.sword3Location != nil {
                out.append(.considerSword3)
            }
        }

        // dungeon completion + found count (`:1626-1637`). Re-arm when a dungeon is
        // un-completed (T-095), so re-completing it re-announces.
        for d in 0...7 {
            if dungeonTracker.dungeon(d).isComplete {
                if !haveAnnouncedCompletedDungeons[d] {
                    out.append(.completedDungeon(d))
                    haveAnnouncedCompletedDungeons[d] = true
                }
            } else {
                haveAnnouncedCompletedDungeons[d] = false
            }
        }
        let numFound = (0...8).reduce(0) { $0 + (mapState.dungeonLocations[$1] != nil ? 1 : 0) }
        // Re-arm the count reminders when the count drops (T-095, unmark→remark):
        // clamp the "already announced" watermark down to the current count so
        // re-reaching a level re-announces.
        previouslyAnnouncedFoundDungeonCount = min(previouslyAnnouncedFoundDungeonCount, numFound)
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
        previouslyAnnouncedTriforceCount = min(previouslyAnnouncedTriforceCount, triforces)
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
            // 0…8 (incl. L9): a blocked item can have come from any dungeon (T-090).
            for i in 0...8 where dungeonTracker.dungeon(i).boxes.contains(where: { $0.cellCurrent == item }) {
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
            for i in 0...8 {   // incl. L9 (T-090)
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
            for i in 0...8 where i != fromDungeon {   // incl. L9 (T-090)
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

        // One-shot "don't forget you have X" nudges. The latch **re-arms when the
        // item is unmarked** (T-095), so if you unmark then re-mark it, the reminder
        // fires again — matching the user's expectation. Recorder + power bracelet
        // are new here (T-095): the user wanted a plain "you have the recorder" nudge
        // instead of the old perpetual "N recorder spots" count.
        itemNudge(ITEMS.ladder, have: playerState.haveLadder, reminded: &remindedLadder, into: &out)
        itemNudge(ITEMS.anyKey, have: playerState.haveAnyKey, reminded: &remindedAnyKey, into: &out)
        itemNudge(ITEMS.recorder, have: playerState.haveRecorder, reminded: &remindedRecorder, into: &out)
        itemNudge(ITEMS.powerBracelet, have: playerState.havePowerBracelet, reminded: &remindedPowerBracelet, into: &out)

        // book → visit hints (T-092, fixed T-094): once you hold the Book and this
        // seed's Book grants hints, nudge to go read the hint NPCs. "Hold the Book"
        // means either the normal Book of Magic (item slot 0, when it's the book and
        // not a shield) OR the boomstick book — which is the *same* book, just moved
        // into a shop with extra wand functionality (so it grants hints too). Re-arms
        // when the book is unmarked (T-095).
        let hasTheBook = (playerState.haveBookOrShield && isCurrentlyBook) || progress.hasBoomBook
        if hasTheBook {
            if bookForHelpfulHints, !remindedBookHints {
                out.append(.remindVisitHints)
                remindedBookHints = true
            }
        } else {
            remindedBookHints = false
        }

        // door-repair count (`Z1R_WPF/Reminders.fs:244-250`): each time a new
        // door-repair charge is marked on the overworld, announce the running
        // count. Not reset on groundhog — door-repair marks are permanent.
        if doorRepairFound > previouslyAnnouncedDoorRepairCount {
            out.append(.doorRepairCount(found: doorRepairFound, max: doorRepairMax))
            previouslyAnnouncedDoorRepairCount = doorRepairFound
        }

        // secret counts (T-105, beyond the reference): when a size's remaining
        // crosses to 1 (one left) or 0 (none left), announce once — so you don't
        // over-mark. Fixed size order for deterministic output.
        for size in [SecretSize.large, .medium, .small] {
            guard let remaining = secretRemaining[size] else { continue }
            if lastSecretRemaining[size] != remaining, remaining == 0 || remaining == 1 {
                out.append(.secretsRemaining(size: size, remaining: remaining))
            }
            lastSecretRemaining[size] = remaining
        }

        // Periodic reminders (`Z1R_WPF/Reminders.fs:193-243`), gated by wall-clock
        // cooldowns (the caller passes `now`).

        // coast item — every 3 min while you have the ladder but not the coast item.
        if cooldownElapsed(now, lastCoastReminder, minutes: 3),
           playerState.haveLadder, !playerState.haveCoastItem {
            if coastItemValue == -1 {
                out.append(.getCoastItem(itemName: nil))
            } else if !(coastItemValue == ITEMS.whiteSword && progress.hasMagicalSword) {
                // (skip nagging for the white sword once you already have the mags)
                out.append(.getCoastItem(itemName: ITEMS.spokenName(coastItemValue, isBook: isCurrentlyBook)))
            }
            lastCoastReminder = now
        }

        // armos item — every 3 min while it's located on the map but not yet obtained
        // (T-185, user request). Derived from existing state (no new poll params).
        if cooldownElapsed(now, lastArmosReminder, minutes: 3),
           mapState.armosLocation != nil, !dungeonTracker.armosBox.isDone {
            let v = dungeonTracker.armosBox.cellCurrent
            out.append(.getArmosItem(itemName: v == -1 ? nil : ITEMS.spokenName(v, isBook: isCurrentlyBook)))
            lastArmosReminder = now
        }

        // (Recorder / power-bracelet spot-count reminders removed in T-095 — they
        //  nagged every 5 min and the count was wrong; replaced by the one-shot
        //  "you have the recorder / power bracelet" nudges above.)

        // boomstick book — every 5 min in a boomstick seed (slot 0 is the shield, so
        // the book is relocated to a shop: `!isCurrentlyBook`) if you have the wand, no
        // book yet, and a book shop is marked. Gating on the boomstick flag means
        // turning it off clears the nudge (T-193: it used to keep firing regardless of
        // the flag). Timer resets only when it actually fires.
        if cooldownElapsed(now, lastBoomstickReminder, minutes: 5),
           !isCurrentlyBook, playerState.haveWand, !progress.hasBoomBook, bookShopMarked {
            out.append(.considerBoomstickBook)
            lastBoomstickReminder = now
        }

        return out
    }
}
