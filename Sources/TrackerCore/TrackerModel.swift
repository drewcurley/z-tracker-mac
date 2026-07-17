import Foundation
import Observation

/// The UI-agnostic tracker state, mirroring the reference app's
/// UI-framework-agnostic F# core (see docs/architecture.md § 2).
///
/// Covers the startup screen's core toggles (docs/domain.md § 4.1, T-003).
/// The full state (dungeon items, overworld tiles, blockers, timeline, the
/// embedded settings panel — see docs/domain.md) is out of scope here and
/// lands incrementally in later feature tasks, each updating
/// docs/contracts.md as it goes.
@Observable
public final class TrackerModel {
    public private(set) var quest: OverworldQuest?

    /// Pre-fills each dungeon's first item box with a Heart Container
    /// (docs/domain.md § 4.1). Off by default, matching the reference app.
    public var heartShuffle: Bool

    /// Hides which numbered dungeon is which, changing several UI behaviors
    /// elsewhere (docs/domain.md § 4.1–4.2). Off by default.
    public var hideDungeonNumbers: Bool

    /// The overworld map's tile-mark state (docs/domain.md § 4.5, T-006).
    /// Owned here since `TrackerModel` is documented as the eventual home
    /// for all main-tracker-view state, not a separate parallel container.
    public let overworldGrid: OverworldGrid

    /// Seed-configured starting inventory (docs/domain.md § 6, T-012 —
    /// foundation piece of the player-state layer; `PlayerComputedStateSummary`
    /// derivation that actually consumes this lands in T-014).
    public let startingItemsAndExtras: StartingItemsAndExtras

    /// Runtime-acquired player progress not tied to a dungeon-box location
    /// (docs/domain.md § 6, T-012).
    public let playerProgress: PlayerProgressAndTakeAnyHearts

    /// The nine dungeons' item/completion/triforce state plus the three
    /// standalone boxes (docs/domain.md § 6, T-013). DEFAULT mode only —
    /// Hidden Dungeon Numbers is T-016. `PlayerComputedStateSummary`, the
    /// glue that turns these boxes into `HaveLadder`/`SwordLevel`/etc., is
    /// T-014.
    /// `private(set) var` (not `let`) because toggling Hidden Dungeon Numbers
    /// live (T-049) rebuilds it with the other `kind` — the box structure and
    /// completion rules differ between modes. Use `setHideDungeonNumbers` /
    /// `setHeartShuffle` rather than mutating the flags directly so the tracker
    /// stays in sync.
    public private(set) var dungeonTracker: DungeonTrackerInstance

    /// Seed flag: in some seed variants the White-Sword and Magical-Sword
    /// item slots are Bomb-Upgrade slots instead, so they don't raise the
    /// player's sword level. The one seed-option flag
    /// `PlayerComputedStateSummary.compute` branches on (T-014;
    /// `TrackerModel.fs:170-176`, read at `:911`/`:924`). Its sibling flags
    /// `IsCurrentlyBook`/`IsBookAnAtlas` gate `PlayerHasTheBook` /
    /// `PlayerCanSeeMapOfThisDungeon`, which are deferred with their own
    /// consumers — so they're added when those land, not here.
    public var isWSMSReplacedByBU: Bool

    /// Seed flag: whether item slot 0 is the Book (`true`, default) or the
    /// Magic Shield (`false`) — in boomstick seeds the book is a shield in the
    /// item pool (`IsCurrentlyBook`, `TrackerModel.fs:156-168`;
    /// `CustomComboBoxes.fs:46`). Consumed immediately by the item-icon display
    /// (book vs shield sprite); the deferred `PlayerHasTheBook` logic helper is
    /// separate and lands with its own consumer.
    public var isCurrentlyBook: Bool

    /// Seed flag: whether the overworld is **mirrored** East↔West (T-047).
    /// Ported from `TrackerModel.MirrorOverworld` (`TrackerModel.fs:31`,
    /// options-menu "Mirror overworld — Flip the overworld map East<->West").
    /// Flips the map display (and feeds the mirrored screen-scroll routing edge
    /// `MapStateSummary` already reads). Off by default.
    public var mirrorOverworld: Bool

    /// The "Progress" flag (T-035.10): when on, the compact items+hearts HUD is
    /// broken out into a separate, placeable window (it also shows on hover of
    /// the Flags checkbox regardless).
    public var showProgressWindow: Bool = false

    /// The overworld screen the player spawned on (T-035.8), or `nil` if unset.
    /// Ported from `startIconX/startIconY` (`TrackerModel.fs:1295`, `NOTFOUND` =
    /// unset). Rendered as a lime/violet ring on the map; purely a marker.
    public var startSpot: OverworldScreenCoordinate? = nil

    /// Recorder-warp destination settings (T-035.7). `recorderToNewDungeons`
    /// (default true) selects discovered map locations vs the fixed vanilla-1Q
    /// screens; `recorderToUnbeatenDungeons` (default false) inverts the triforce
    /// filter to not-yet-beaten dungeons. Ported from `TrackerModel.fs:1293-1294`.
    public var recorderToNewDungeons: Bool = true
    public var recorderToUnbeatenDungeons: Bool = false
    /// Which of the ordered available recorder destinations is "current" — the
    /// whistle-count position the below-map stepper points at (T-035.7). Wraps
    /// against the live destination list; stepping it mirrors whistling in game.
    public var recorderDestinationIndex: Int = 0
    /// Whether the user has manually stepped the recorder destination with the
    /// arrows (T-081). While `false`, the Info-area widget auto-tracks the lowest
    /// obtained-triforce dungeon; the first arrow press pins it to `recorderDestinationIndex`.
    public var recorderDestinationManual: Bool = false

    /// Per-target location hints (T-039) — which overworld region each dungeon /
    /// sword cave was hinted to be in. 11 slots (`HintTarget`: dungeons 1–9 →
    /// 0–8, white sword → 9, magical sword → 10). Map *knowledge*, so a
    /// groundhog reset keeps these.
    public var levelHints: [HintZone]

    /// Free-text notes (T-019.1) — the reference's single global notes box
    /// (`WPFUI.fs:1219-1229`). Player *knowledge*, so a groundhog reset keeps it
    /// (like `levelHints`). Session-only for now; persistence rides with the
    /// future save/load.
    public var notes: String = ""

    /// Per-dungeon "why I left" blocker annotations (docs/domain.md § 6,
    /// T-017). Reads player state for staleness but doesn't feed back into
    /// it. The blocker-setting UI is a later task (uncharacterized).
    public let dungeonBlockers: DungeonBlockersContainer

    /// The nine dungeons' room maps (T-019.3) — the 8×8 room-type/monster/
    /// floor-drop/door grids. Grid *knowledge*, so a groundhog reset keeps them.
    /// Indexed `0…8` for dungeons 1–9.
    public let dungeonRoomMaps: [DungeonRoomMap] = (0..<9).map { _ in DungeonRoomMap() }

    /// The edge-triggered reminder/announcement engine (T-018.2). Owned here
    /// so its transition state survives view redraws; driven by the app's
    /// poll loop via `pollReminders()` (T-018.3).
    public let reminderEngine: ReminderEngine

    /// The Timeline's data (T-098): item-acquisition splits + finish snapshot.
    /// Fed once a second from the app's poll loop (`recordTimeline`).
    public let timeline = TimelineModel()

    public init(
        quest: OverworldQuest? = nil,
        heartShuffle: Bool = false,
        hideDungeonNumbers: Bool = false,
        overworldGrid: OverworldGrid = OverworldGrid(),
        startingItemsAndExtras: StartingItemsAndExtras = StartingItemsAndExtras(),
        playerProgress: PlayerProgressAndTakeAnyHearts = PlayerProgressAndTakeAnyHearts(),
        dungeonTracker: DungeonTrackerInstance = DungeonTrackerInstance(),
        isWSMSReplacedByBU: Bool = false,
        isCurrentlyBook: Bool = true,
        mirrorOverworld: Bool = false,
        levelHints: [HintZone] = Array(repeating: .unknown, count: HintTarget.count),
        dungeonBlockers: DungeonBlockersContainer = DungeonBlockersContainer(),
        reminderEngine: ReminderEngine = ReminderEngine()
    ) {
        self.quest = quest
        self.heartShuffle = heartShuffle
        self.hideDungeonNumbers = hideDungeonNumbers
        self.overworldGrid = overworldGrid
        self.startingItemsAndExtras = startingItemsAndExtras
        self.playerProgress = playerProgress
        self.dungeonTracker = dungeonTracker
        self.isWSMSReplacedByBU = isWSMSReplacedByBU
        self.isCurrentlyBook = isCurrentlyBook
        self.mirrorOverworld = mirrorOverworld
        self.levelHints = levelHints
        self.dungeonBlockers = dungeonBlockers
        self.reminderEngine = reminderEngine
    }

    /// Polls the reminder engine with the model's current derived state,
    /// returning the announcements to fire this tick (T-018.3). The app calls
    /// this on a ~1 Hz timer. The map-state's routing flags don't affect any
    /// reminder input, so they're passed as `false`.
    /// Fold the current state into the Timeline (T-098) at `elapsedSeconds` of run
    /// time — stamps newly-acquired items, drops un-marked ones, and captures the
    /// finish snapshot when Zelda is rescued. Called once a second by the poll loop.
    public func recordTimeline(elapsedSeconds: Int) {
        let instance = OverworldInstance(quest: quest ?? .first)
        let mapState = MapStateSummary.compute(
            grid: overworldGrid, instance: instance, dungeonTracker: dungeonTracker,
            playerState: playerComputedStateSummary, progress: playerProgress,
            drawRoutes: false, routesCanScreenScroll: false, mirrorOverworld: false)
        let acquired = TimelineEvents.current(
            playerState: playerComputedStateSummary, progress: playerProgress,
            dungeonTracker: dungeonTracker, isCurrentlyBook: isCurrentlyBook)
        timeline.record(elapsedSeconds: elapsedSeconds, acquired: acquired,
                        owRemaining: mapState.owSpotsRemain, finished: playerProgress.hasRescuedZelda)
    }

    public func pollReminders(bookForHelpfulHints: Bool = false) -> [ReminderAnnouncement] {
        let instance = OverworldInstance(quest: quest ?? .first)
        let mapState = MapStateSummary.compute(
            grid: overworldGrid, instance: instance, dungeonTracker: dungeonTracker,
            playerState: playerComputedStateSummary, progress: playerProgress,
            drawRoutes: false, routesCanScreenScroll: false, mirrorOverworld: false)
        let tag = TriforceAndGoSummary.compute(
            playerState: playerComputedStateSummary, dungeonTracker: dungeonTracker,
            mapState: mapState, progress: playerProgress, grid: overworldGrid, instance: instance)
        // Door-repair charges + book-shop presence marked on the overworld.
        let q = quest ?? .first
        var doorRepairFound = 0
        var bookShopMarked = false
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                switch overworldGrid.mark(column: c, row: r) {
                case .doorRepair: doorRepairFound += 1
                case .shop(.book): bookShopMarked = true
                default: break
                }
            }
        }
        return reminderEngine.poll(
            playerState: playerComputedStateSummary, mapState: mapState,
            dungeonTracker: dungeonTracker, blockers: dungeonBlockers,
            progress: playerProgress, startingItems: startingItemsAndExtras, tagSummary: tag,
            doorRepairFound: doorRepairFound,
            doorRepairMax: OverworldTileLimits.maxUses(.doorRepair, quest: q),
            now: Date(),
            coastItemValue: dungeonTracker.ladderBox.cellCurrent,
            isCurrentlyBook: isCurrentlyBook,
            bookShopMarked: bookShopMarked,
            bookForHelpfulHints: bookForHelpfulHints)
    }

    /// The derived player state (item possession, levels, hearts) read by
    /// routing/GYR and, later, the item tracker and reminders. Recomputed on
    /// demand from `startingItemsAndExtras`, `playerProgress`, and
    /// `dungeonTracker` (T-014). Because those inputs are all `@Observable`,
    /// reading this inside a SwiftUI view re-derives it whenever any of them
    /// changes.
    public var playerComputedStateSummary: PlayerComputedStateSummary {
        PlayerComputedStateSummary.compute(
            dungeonTracker: dungeonTracker,
            startingItems: startingItemsAndExtras,
            progress: playerProgress,
            isWSMSReplacedByBU: isWSMSReplacedByBU
        )
    }

    /// "Groundhog / routers / 4+4" reset — **remove inventory but preserve
    /// maps** (`OverworldItemGridUI.fs:678-717` reset button;
    /// `ResetForGroundhogOrRoutersOrFourPlusFourEtc`). For replaying the same
    /// seed from scratch while keeping everything you've learned:
    ///
    /// **Reset** (run progress): dungeon triforces; every non-`.skipped` box's
    /// *possession* (`.no`) while keeping its item *identity* and skipped marks;
    /// all `playerProgress` (progress items + take-any hearts — the "used"
    /// state); the reminder engine (so announcements fire again).
    ///
    /// **Kept** (knowledge): the overworld tile marks, the box item identities,
    /// dungeon labels, blockers (`:709` keeps them for 4+4 keyblock), and the
    /// seed's starting items (`startingItemsAndExtras` is not reset — same seed).
    ///
    /// The reference makes a hard save first; this app has no save/load yet, so
    /// callers should confirm before invoking (the operation is destructive).
    public func resetForGroundhogOrRouters() {
        // Remove triforces (dungeons 1–8; dungeon 9 has none).
        for i in 0..<8 where dungeonTracker.dungeon(i).playerHasTriforce {
            dungeonTracker.dungeon(i).toggleTriforce()
        }
        // Red-ify obtained items: keep the item identity + any SKIPPED marks,
        // reset "have it" → NO.
        for box in dungeonTracker.allBoxes() where box.playerHas != .skipped {
            box.setPlayerHas(.no)
        }
        // Clear progress items + take-any hearts (their "used" state).
        playerProgress.resetAll()
        // Clear the overworld tiles' claimed ("used") state — a replay
        // re-collects them — while keeping the marks (T-058).
        overworldGrid.clearAllUsed()
        // Let reminders announce again.
        reminderEngine.resetForGroundhogOrRouters()
    }

    /// Auto-map the vanilla dungeon locations for first or second quest
    /// (T-035.x): clear every existing `.dungeon(_)` mark, then set dungeons
    /// 1–9 at their canonical screens (`OverworldVanillaDungeons`). Other marks
    /// (shops, secrets, …) are left alone, except a vanilla coordinate that
    /// currently holds a take-any tile, whose Items-group slot is released first
    /// (T-066) before it's overwritten. Destructive — callers confirm first.
    public func autoMapVanillaDungeons(secondQuest: Bool) {
        let locations = secondQuest
            ? OverworldVanillaDungeons.secondQuest
            : OverworldVanillaDungeons.firstQuest
        // Remove all prior dungeon marks so the result is exactly these nine.
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                if case .dungeon = overworldGrid.mark(column: c, row: r) {
                    overworldGrid.setMark(.unmarked, column: c, row: r)
                }
            }
        }
        for (i, loc) in locations.enumerated() {
            if overworldGrid.mark(column: loc.column, row: loc.row) == .takeAny {
                releaseOverworldTakeAny(column: loc.column, row: loc.row)
            }
            overworldGrid.setMark(.dungeon(i + 1), column: loc.column, row: loc.row)
        }
    }

    // MARK: Overworld take-any ⇄ Items-group heart-slot sync (T-066)

    /// Mark an overworld tile as a `.takeAny` with `state`, keeping its linked
    /// Items-group heart slot in sync. The tile owns exactly one slot: if it
    /// already has one, that same slot is updated (so re-marking the tile a
    /// different way never fills a second slot); otherwise the next slot not
    /// already owned by a take-any tile (and currently empty) is claimed.
    /// `.untaken` frees the tile's slot back to an empty heart. Fixes the T-057
    /// bug where re-marking double-recorded and clearing left the slot stranded.
    public func setOverworldTakeAny(_ state: TakeAnyHeartState, column: Int, row: Int) {
        overworldGrid.setMark(.takeAny, column: column, row: row)
        let existing = overworldGrid.takeAnySlot(column: column, row: row)
        if state == .untaken {
            if let existing { playerProgress.takeAnyHearts[existing] = .untaken }
            overworldGrid.setTakeAnySlot(nil, column: column, row: row)
            overworldGrid.setUsed(false, column: column, row: row)
            return
        }
        let slot = existing ?? firstClaimableTakeAnySlot()
        if let slot {
            playerProgress.takeAnyHearts[slot] = state
            overworldGrid.setTakeAnySlot(slot, column: column, row: row)
        }
        overworldGrid.setUsed(true, column: column, row: row)
    }

    /// Left-click cycling of a take-any tile (untaken → heart → potion → candle
    /// → …), routed through `setOverworldTakeAny` so its slot stays in sync.
    public func cycleOverworldTakeAny(column: Int, row: Int) {
        let current = overworldGrid.takeAnySlot(column: column, row: row)
            .map { playerProgress.takeAnyHearts[$0] } ?? .untaken
        setOverworldTakeAny(current.cycled(by: 1), column: column, row: row)
    }

    /// Free a tile's linked Items-group slot (back to an empty heart) — called
    /// when a take-any tile is changed to another mark or cleared (T-066).
    /// A no-op if the tile owns no slot.
    public func releaseOverworldTakeAny(column: Int, row: Int) {
        guard let slot = overworldGrid.takeAnySlot(column: column, row: row) else { return }
        playerProgress.takeAnyHearts[slot] = .untaken
        overworldGrid.setTakeAnySlot(nil, column: column, row: row)
    }

    /// Cycle an Items-group heart box directly, reflecting the change back onto
    /// the linked take-any tile's dim so the two stay in sync (T-066).
    public func cycleTakeAnySlot(_ index: Int, by delta: Int) {
        let next = playerProgress.takeAnyHearts[index].cycled(by: delta)
        playerProgress.takeAnyHearts[index] = next
        if let tile = overworldGrid.tileForTakeAnySlot(index) {
            overworldGrid.setUsed(next != .untaken, column: tile.column, row: tile.row)
        }
    }

    /// The first Items-group slot that is empty **and** not already owned by a
    /// take-any tile — the slot a newly-claimed tile may take (T-066).
    private func firstClaimableTakeAnySlot() -> Int? {
        let owned = overworldGrid.linkedTakeAnySlots()
        return (0..<playerProgress.takeAnyHearts.count).first {
            !owned.contains($0) && playerProgress.takeAnyHearts[$0] == .untaken
        }
    }

    /// Selects the overworld quest for this run. Mirrors the reference app's
    /// startup-screen quest buttons (docs/domain.md § 4.1) — once a quest is
    /// chosen, the reference app moves from the startup screen to the main
    /// tracker view; wiring that transition is `StartupView`'s concern, not
    /// this model's (the model just records the choice).
    public func selectQuest(_ quest: OverworldQuest) {
        self.quest = quest
        // At session start, seed the dungeon floor-item hearts per Heart
        // Shuffle (the reference's `makeAll` does this once the quest is
        // chosen — `UI.fs:142-144`).
        dungeonTracker.applyFloorItemHearts(heartShuffle: heartShuffle)
    }

    /// Toggle Heart Shuffle live (T-049 — the flag now lives in the in-app Flags
    /// group, not just the startup screen). Re-seeds the dungeon floor-item
    /// hearts: **off** puts a known Heart Container in dungeons 1–8's first box,
    /// **on** empties them (hearts shuffled into the pool).
    public func setHeartShuffle(_ on: Bool) {
        heartShuffle = on
        dungeonTracker.applyFloorItemHearts(heartShuffle: on)
    }

    /// Toggle Hidden Dungeon Numbers live (T-049). HDN changes the dungeon
    /// structure (3 boxes per dungeon vs 2, different completion rules), so the
    /// tracker is **rebuilt** with the other `kind` — dungeon progress resets,
    /// as befits a structural seed choice. The second-quest-dungeons choice is
    /// preserved, and the floor-item hearts are re-seeded for the new boxes.
    public func setHideDungeonNumbers(_ on: Bool) {
        guard on != hideDungeonNumbers else { return }
        hideDungeonNumbers = on
        dungeonTracker = DungeonTrackerInstance(
            kind: on ? .hideDungeonNumbers : .default,
            isSecondQuestDungeons: dungeonTracker.isSecondQuestDungeons
        )
        dungeonTracker.applyFloorItemHearts(heartShuffle: heartShuffle)
    }
}
