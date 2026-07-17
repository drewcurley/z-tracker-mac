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
    case defeatedGanon, rescuedZelda
    /// Dungeon triforce 1…8.
    case triforce(Int)
    /// Take-any heart 1…4.
    case takeAnyHeart(Int)

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
        case .defeatedGanon: "Ganon"
        case .rescuedZelda: "Zelda"
        case .triforce(let n): "Triforce \(n)"
        case .takeAnyHeart(let n): "Take-Any Heart \(n)"
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
        dungeonTracker: DungeonTrackerInstance,
        isCurrentlyBook: Bool
    ) -> Set<TimelineEvent> {
        var s: Set<TimelineEvent> = []
        // Sword / candle / ring / arrow / boomerang progressions (each threshold
        // crossing is its own event).
        if playerState.swordLevel >= 1 { s.insert(.woodSword) }
        if playerState.swordLevel >= 2 { s.insert(.whiteSword) }
        if playerState.swordLevel >= 3 { s.insert(.magicalSword) }
        if playerState.candleLevel >= 1 { s.insert(.blueCandle) }
        if playerState.candleLevel >= 2 { s.insert(.redCandle) }
        if playerState.ringLevel >= 1 { s.insert(.blueRing) }
        if playerState.ringLevel >= 2 { s.insert(.redRing) }
        if playerState.arrowLevel >= 1 { s.insert(.woodArrow) }
        if playerState.arrowLevel >= 2 { s.insert(.silverArrow) }
        if playerState.boomerangLevel >= 1 { s.insert(.boomerang) }
        if playerState.boomerangLevel >= 2 { s.insert(.magicBoomerang) }
        // Singleton items.
        if playerState.haveBookOrShield, isCurrentlyBook { s.insert(.book) }
        if progress.hasBoomBook { s.insert(.boomstickBook) }
        if playerState.haveBow { s.insert(.bow) }
        if playerState.haveWand { s.insert(.wand) }
        if playerState.havePowerBracelet { s.insert(.powerBracelet) }
        if playerState.haveRaft { s.insert(.raft) }
        if playerState.haveRecorder { s.insert(.recorder) }
        if playerState.haveAnyKey { s.insert(.anyKey) }
        if playerState.haveLadder { s.insert(.ladder) }
        if progress.hasDefeatedGanon { s.insert(.defeatedGanon) }
        if progress.hasRescuedZelda { s.insert(.rescuedZelda) }
        // Triforces 1…8.
        for n in 1...8 where dungeonTracker.dungeon(n - 1).playerHasTriforce { s.insert(.triforce(n)) }
        // Take-any hearts (only the "took a heart" state counts).
        for n in 1...4 where progress.takeAnyHearts[n - 1] == .takenHeart { s.insert(.takeAnyHeart(n)) }
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

    public init() {}

    /// Fold the current state into the timeline: stamp newly-acquired events with
    /// `elapsedSeconds`, drop events that were un-marked (so re-acquiring re-stamps
    /// — matching the reminder engine's re-fire behavior), and capture/clear the
    /// finish snapshot.
    public func record(elapsedSeconds: Int, acquired: Set<TimelineEvent>, owRemaining: Int, finished: Bool) {
        for e in acquired where acquiredAt[e] == nil {
            acquiredAt[e] = elapsedSeconds
        }
        for e in acquiredAt.keys where !acquired.contains(e) {
            acquiredAt.removeValue(forKey: e)
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
    }
}
