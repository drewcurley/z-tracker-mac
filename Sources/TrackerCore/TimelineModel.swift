import Observation

/// One thing that can appear on the Timeline (T-098) — an item, a triforce, a
/// take-any heart, or ganon/zelda. A subset of the reference's `TimelineID`
/// (`Z1R_WPF/Timeline.fs:11-57`); box-location markers and custom user items are
/// deferred to a later phase.
public enum TimelineEvent: Hashable, Sendable {
    case woodSword, whiteSword, magicalSword
    case boomerang, magicBoomerang
    case woodArrow, silverArrow
    case blueCandle, redCandle
    case blueRing, redRing
    case book, boomstickBook
    case bow, wand, powerBracelet, raft, recorder, anyKey, ladder
    /// Bait (a.k.a. meat) — beyond the reference timeline list, user request (T-113).
    case bait
    case defeatedGanon, rescuedZelda
    /// Dungeon triforce 1…8.
    case triforce(Int)
    /// Take-any heart 1…4.
    case takeAnyHeart(Int)
    /// A heart container collected from dungeon slot 1…9's boxes (T-113).
    case dungeonHeart(Int)
    /// A heart container that was the coast item (T-113).
    case coastHeart

    /// The order events sort in when they share a minute (roughly acquisition
    /// significance), and the human-readable name shown on hover.
    public var displayName: String {
        switch self {
        case .woodSword: "Wood Sword"
        case .whiteSword: "White Sword"
        case .magicalSword: "Magical Sword"
        case .boomerang: "Boomerang"
        case .magicBoomerang: "Magic Boomerang"
        case .woodArrow: "Wood Arrow"
        case .silverArrow: "Silver Arrow"
        case .blueCandle: "Blue Candle"
        case .redCandle: "Red Candle"
        case .blueRing: "Blue Ring"
        case .redRing: "Red Ring"
        case .book: "Book"
        case .boomstickBook: "Boomstick Book"
        case .bow: "Bow"
        case .wand: "Wand"
        case .powerBracelet: "Power Bracelet"
        case .raft: "Raft"
        case .recorder: "Recorder"
        case .anyKey: "Any Key"
        case .ladder: "Ladder"
        case .bait: "Bait"
        case .defeatedGanon: "Ganon"
        case .rescuedZelda: "Zelda"
        case .triforce(let n): "Triforce \(n)"
        case .takeAnyHeart(let n): "Take-Any Heart \(n)"
        case .dungeonHeart(let n): "Dungeon \(n) Heart"
        case .coastHeart: "Coast Heart"
        }
    }
}

/// Computes which timeline events are **currently acquired** from live tracker
/// state. The `TimelineModel` diffs this against what it has stamped to record
/// first-acquisition times.
public enum TimelineEvents {
    public static func current(
        playerState: PlayerComputedStateSummary,
        progress: PlayerProgressAndTakeAnyHearts,
        startingItems: StartingItemsAndExtras,
        dungeonTracker: DungeonTrackerInstance,
        isWSMSReplacedByBU: Bool,
        isCurrentlyBook: Bool
    ) -> Set<TimelineEvent> {
        var s: Set<TimelineEvent> = []
        let boxes = dungeonTracker.allBoxes()
        /// Whether some collected box actually holds `item` (an "actual pickup").
        func boxHas(_ item: Int) -> Bool {
            boxes.contains { $0.playerHas == .yes && $0.cellCurrent == item }
        }

        // Tiered items (sword / candle / ring / arrow / boomerang): each specific
        // tier is its own event, driven by whether you actually hold *that* item
        // — NOT by a cumulative level (T-113). Deriving from a level made, e.g.,
        // "wood arrow" light up the moment you got the silver arrow, even though
        // you never picked up wood arrows. Sources mirror `PlayerComputedState`.
        if progress.hasWoodSword { s.insert(.woodSword) }
        if startingItems.hasWhiteSword || (boxHas(ITEMS.whiteSword) && !isWSMSReplacedByBU) { s.insert(.whiteSword) }
        if (progress.hasMagicalSword || startingItems.hasMagicalSword) && !isWSMSReplacedByBU { s.insert(.magicalSword) }
        if progress.hasBlueCandle { s.insert(.blueCandle) }
        if startingItems.hasRedCandle || boxHas(ITEMS.redCandle) { s.insert(.redCandle) }
        if progress.hasBlueRing { s.insert(.blueRing) }
        if startingItems.hasRedRing || boxHas(ITEMS.redRing) { s.insert(.redRing) }
        if progress.hasWoodArrow { s.insert(.woodArrow) }
        if startingItems.hasSilverArrow || boxHas(ITEMS.silverArrow) { s.insert(.silverArrow) }
        if startingItems.hasBoomerang || boxHas(ITEMS.boomerang) { s.insert(.boomerang) }
        if startingItems.hasMagicBoomerang || boxHas(ITEMS.magicBoomerang) { s.insert(.magicBoomerang) }

        // Singleton items (already presence-based, no tier conflation).
        if playerState.haveBookOrShield, isCurrentlyBook { s.insert(.book) }
        if progress.hasBoomBook { s.insert(.boomstickBook) }
        if playerState.haveBow { s.insert(.bow) }
        if playerState.haveWand { s.insert(.wand) }
        if playerState.havePowerBracelet { s.insert(.powerBracelet) }
        if playerState.haveRaft { s.insert(.raft) }
        if playerState.haveRecorder { s.insert(.recorder) }
        if playerState.haveAnyKey { s.insert(.anyKey) }
        if playerState.haveLadder { s.insert(.ladder) }
        if progress.hasMeat { s.insert(.bait) }
        if progress.hasDefeatedGanon { s.insert(.defeatedGanon) }
        if progress.hasRescuedZelda { s.insert(.rescuedZelda) }

        // Triforces 1…8.
        for n in 1...8 where dungeonTracker.dungeon(n - 1).playerHasTriforce { s.insert(.triforce(n)) }
        // Take-any hearts (only the "took a heart" state counts).
        for n in 1...4 where progress.takeAnyHearts[n - 1] == .takenHeart { s.insert(.takeAnyHeart(n)) }
        // Heart containers collected from dungeon boxes and the coast (T-113):
        // previously only take-any hearts showed on the timeline.
        for n in 1...9 {
            let held = dungeonTracker.dungeon(n - 1).boxes.contains {
                $0.playerHas == .yes && $0.cellCurrent == ITEMS.heartContainer
            }
            if held { s.insert(.dungeonHeart(n)) }
        }
        let coast = dungeonTracker.ladderBox
        if coast.playerHas == .yes, coast.cellCurrent == ITEMS.heartContainer { s.insert(.coastHeart) }
        return s
    }
}

/// The Timeline's data (T-098): when each event was first acquired (elapsed run
/// seconds) and the finish snapshot. Ported from the reference's per-item
/// `FinishedTotalSeconds` + `timelineDataOverworldSpotsRemain`
/// (`Z1R_WPF/Timeline.fs`). The overworld-progress series (phase 2) is added
/// later; this phase is the item strip. Session-only until Save/Load lands.
@Observable
public final class TimelineModel {
    /// Event → elapsed run seconds at first acquisition.
    public private(set) var acquiredAt: [TimelineEvent: Int] = [:]
    /// The elapsed seconds when Zelda was rescued (the run finished), or `nil`.
    public private(set) var finishSeconds: Int?
    /// Overworld spots still unmarked at the finish, or `nil`.
    public private(set) var finishOwRemaining: Int?

    /// One (time, remaining) sample of the overworld-progress graph (T-099).
    public struct OverworldRemainingSample: Sendable, Equatable {
        public let seconds: Int
        public let remaining: Int
        public init(seconds: Int, remaining: Int) { self.seconds = seconds; self.remaining = remaining }
    }
    /// The overworld-spots-remaining series over run time — appended only when the
    /// count changes, so it stays compact. Drives the phase-2 line graph.
    public private(set) var owRemainingSamples: [OverworldRemainingSample] = []
    /// The most recent elapsed run seconds seen (the graph's right edge / "now").
    public private(set) var latestSeconds: Int = 0

    public init() {}

    /// Fold the current state into the timeline: stamp newly-acquired events with
    /// `elapsedSeconds`, drop events that were un-marked (so re-acquiring re-stamps
    /// — matching the reminder engine's re-fire behavior), and capture/clear the
    /// finish snapshot.
    public func record(elapsedSeconds: Int, acquired: Set<TimelineEvent>, owRemaining: Int, finished: Bool) {
        latestSeconds = elapsedSeconds
        for e in acquired where acquiredAt[e] == nil {
            acquiredAt[e] = elapsedSeconds
        }
        for e in acquiredAt.keys where !acquired.contains(e) {
            acquiredAt.removeValue(forKey: e)
        }
        // Overworld-progress series (T-099): sample only on a change (or first),
        // so the graph line has one point per real transition.
        if owRemainingSamples.last?.remaining != owRemaining {
            owRemainingSamples.append(.init(seconds: elapsedSeconds, remaining: owRemaining))
        }
        if finished {
            if finishSeconds == nil { finishSeconds = elapsedSeconds; finishOwRemaining = owRemaining }
        } else {
            finishSeconds = nil
            finishOwRemaining = nil
        }
    }

    /// Clear everything (a full app reset).
    public func reset() {
        acquiredAt = [:]
        finishSeconds = nil
        finishOwRemaining = nil
        owRemainingSamples = []
        latestSeconds = 0
    }
}
