import AppKit
import CoreGraphics
import SwiftUI
import TrackerCore

/// Wraps a Swift closure as an `@objc` target so it can back an `NSMenuItem` (T-185).
/// Retained via the item's `representedObject` (its `target` is weak).
private final class ClosureMenuTarget: NSObject {
    let run: () -> Void
    init(_ run: @escaping () -> Void) { self.run = run; super.init() }
    @objc func fire() { run() }
}

/// The overworld map (docs/domain.md § 4.5, T-006 core data model +
/// interaction, T-007 tile-mark sprite rendering, T-008 terrain background).
/// Renders the reference app's actual terrain art
/// (`s_map_overworld_vanilla_strip8.png`, per selected quest, via
/// `OverworldBackgroundAtlas`) as the base layer, with tile-mark icons
/// (`s_icon_overworld_strip39.png`, via `OverworldIconAtlas`) composited on
/// top wherever a mark is set. Both assets are MIT-licensed — see
/// `/NOTICE.md`.
///
/// Confirmed gestures implemented: left-click an unmarked tile marks it
/// `.dontCare` ("dark"); left-click a `.dontCare` tile, or right-click any
/// tile, opens a mark-selection menu. The reference app's actual popup UI
/// shape (a custom grid-of-icons picker) is a follow-up — a context menu is
/// this task's functional stand-in, not a guess at the real design.
struct OverworldMapView: View {
    var grid: OverworldGrid
    var quest: OverworldQuest
    var options: TrackerOptions
    /// Shared focus state (T-134) — the keyboard cursor follows hover here and is
    /// drawn on the cursor tile when the cursor is on the overworld.
    @Bindable var focus: TrackerFocusState

    /// Live derived player state (T-014). Supplies real ladder/raft
    /// possession to the routing graph below, replacing T-011's documented
    /// placeholders.
    var playerState: PlayerComputedStateSummary

    /// Live derived overworld map state (T-015.3). Supplies
    /// `owGettableLocations` for the true green/yellow/red highlight cascade
    /// (T-015.4), replacing T-011's flat single-color "reachable" overlay.
    var mapState: MapStateSummary

    /// Top-section map-overlay toggles (T-035.2). `nil` = no overlays.
    var overlays: OverworldOverlayState?
    /// Whether the Armos item has been recorded (gates the late-game open-caves
    /// overlay); supplied by the parent from `dungeonTracker.armosBox`.
    var armosClaimed: Bool = false
    /// The dungeon tracker + icon options (T-106): for the in-place item prompt
    /// that pops up when you mark an Armos or the White-Sword-Item cave.
    var dungeonTracker: DungeonTrackerInstance
    var iconOptions: ItemIconOptions = ItemIconOptions()

    /// Whether the overworld is mirrored East↔West (T-047). Flips the whole map
    /// horizontally (`scaleEffect(x: -1)`), so a tap on the visually-left screen
    /// still edits its true (mirrored) data column — no coordinate remap needed.
    /// Readable glyphs (dungeon numerals, interior icons, fairy, coords) are
    /// counter-flipped so they don't render backwards, matching the reference's
    /// re-flip of `mirrorOverworldFEs` (`UI.fs:1302-1310`).
    var mirrored: Bool = false

    /// Hidden Dungeon Numbers (T-049): dungeon marks are labeled A–H (1–8)
    /// instead of numbers, both in the tile selector and on the map (Level 9
    /// stays "9").
    var hideDungeonNumbers: Bool = false

    /// Whether the player has rescued Zelda (T-004.3) — the endgame reveal that
    /// un-hides every "More settings"-hidden tile kind.
    var hasRescuedZelda: Bool = false

    /// Whether the dungeon in slot `1…9` is 100% complete (all items +
    /// triforce, `Dungeon.isComplete`) — its overworld badge dims to dark
    /// yellow (T-035.6), matching the reference's completed-dungeon shading.
    var dungeonComplete: (Int) -> Bool = { _ in false }

    /// The single **current** recorder-warp destination (T-035.7) — the screen
    /// the whistle would take you to right now, per the stepper below the map.
    /// Gets a lone diamond marker; `nil` when there's no valid destination.
    var recorderDestination: OverworldScreenCoordinate? = nil

    /// The player's start screen (T-035.8) — a lime/violet ring marker; `nil`
    /// when unset. Set/cleared from the tile context menu.
    var startSpot: OverworldScreenCoordinate? = nil
    var onSetStartSpot: (Int, Int) -> Void = { _, _ in }
    var onClearStartSpot: () -> Void = {}
    var customWaypoint: OverworldScreenCoordinate? = nil
    var onSetWaypoint: (Int, Int) -> Void = { _, _ in }
    var onClearWaypoint: () -> Void = {}
    /// A user-imported custom map (T-167); when set, the map renders from it with fog.
    var customMapImagePath: String? = nil

    /// Mark a take-any tile with what was taken, syncing its linked Items-group
    /// heart slot (T-066). `(state, column, row)`.
    var onSetTakeAny: (TakeAnyHeartState, Int, Int) -> Void = { _, _, _ in }
    /// Left-click a take-any tile to cycle its claimed state, keeping its slot
    /// in sync (T-066). `(column, row)`.
    var onCycleTakeAny: (Int, Int) -> Void = { _, _ in }
    /// Free a take-any tile's linked slot when the tile is changed to another
    /// mark or cleared (T-066). `(column, row)`.
    var onReleaseTakeAny: (Int, Int) -> Void = { _, _ in }
    /// Notifies of a mark change (old, new, column, row) for the overworld-overwrite
    /// reminder (T-096).
    var onOverwrite: (OverworldTileMark, OverworldTileMark, Int, Int) -> Void = { _, _, _, _ in }

    /// A dungeon marker was placed (T-039.1) — the parent auto-sets that
    /// dungeon's location hint to the screen's region. `(number, column, row)`.
    var onPlaceDungeon: (Int, Int, Int) -> Void = { _, _, _ in }
    /// The wood-sword cave was toggled used/unused (T-118): grant/ungrant the sword.
    var onWoodSwordCaveUsedChanged: (Bool) -> Void = { _ in }
    /// The magical-sword cave was clicked (T-119): take/untake the magical sword.
    var onMagicalSwordCaveUsedChanged: (Bool) -> Void = { _ in }

    /// The border/fill color an active top-section overlay gives this tile, or nil for
    /// none (T-035.2). Money + open-caves-only use green; the open-caves overlay's second
    /// mode — **all currently-gettable locations** — uses a distinct color (T-189).
    static let overlayGreen = Color.green
    static let allGettableColor = Color.orange

    private func overlayHighlight(column: Int, row: Int, mark: OverworldTileMark) -> Color? {
        guard let overlays else { return nil }
        if overlays.isActive(.money),
           OverworldOverlays.isMoneyTile(mark, secretCollected: grid.isUsed(column: column, row: row)) {
            return Self.overlayGreen
        }
        switch overlays.effectiveOpenCavesMode {
        case .openCaves:
            let pastEarly = OverworldOverlays.openCavesPastEarlyGame(
                woodSwordCaveFound: mapState.woodSwordCaveFound,
                swordLevel: playerState.swordLevel, candleLevel: playerState.candleLevel)
            let hit = OverworldOverlays.isOpenCaveTile(
                mark: mark,
                nothingable: overworldInstance.nothingable(x: column, y: row),
                hasArmos: overworldInstance.hasArmos(x: column, y: row),
                pastEarlyGame: pastEarly, armosClaimed: armosClaimed)
            return hit ? Self.overlayGreen : nil
        case .allGettable:
            return mapState.owGettableLocations[column, row] ? Self.allGettableColor : nil
        case .off:
            return nil
        }
    }

    /// The tile-selector label for a sword *cave* (a location). Relabeled from
    /// "Sword cave N" (user request). These are **not** annotated for swordless:
    /// the "White Sword Item" cave holds a *random* item, and it is the white-
    /// sword *weapon* (`ITEMS.whiteSword`, a shuffled box item) — not the cave —
    /// that the bomb upgrade replaces. The weapon's swap is rendered on the
    /// item boxes/picker, not here.
    nonisolated static func swordCaveLabel(_ number: Int) -> String {
        switch number {
        case 1: return "Wood Sword"
        case 2: return "White Sword Item"
        case 3: return "Magical Sword"
        default: return "Sword cave \(number)"
        }
    }

    /// Aspect ratio matches the reference app's base tile shape (16×11px,
    /// `Graphics.fs` `OMTW`/`OMTH` — resolves a previously-open question in
    /// `docs/domain.md` about the layout's numeric constants) — kept even
    /// though this view doesn't render the real sprites yet, so later sprite
    /// integration doesn't have to fight a mismatched grid shape.
    private let tileAspectRatio: CGFloat = 16.0 / 11.0

    @State private var hoveredVertex: OverworldVertex?
    @State private var routeHighlight: OverworldRouteHighlight?
    /// The tile awaiting an in-place item pick (Armos / White-Sword cave), T-106.
    @State private var itemPrompt: ItemPromptTarget?
    /// The tile whose tile chooser popover is open (T-185) — opened by right-click
    /// (graphical mode) or left-click on a Don't-Care tile (either mode).
    @State private var chooserCell: TileCoord?
    /// The tile whose overworld enemy picker is open — scroll-up in graphical mode (T-185).
    @State private var enemyCell: TileCoord?

    struct ItemPromptTarget: Equatable { let column: Int; let row: Int; let isArmos: Bool }
    struct TileCoord: Identifiable, Equatable { let column: Int; let row: Int; var id: Int { row * 100 + column } }

    /// Ladder and raft are live (`playerState.haveLadder`/`.haveRaft`, T-014)
    /// and any-roads are live (T-015.5). The mirror-overworld toggle
    /// (`MirrorOverworld`) is a full display-flip feature (flips the whole
    /// map's marks + background, not just routing) — split out as its own
    /// task (T-015.7), so it stays a documented placeholder here, not
    /// silently hardcoded. `RoutesCanScreenScroll` is already wired to a real
    /// option below.
    private static let placeholderIsMirror = false

    /// Bold/pale highlight cap, matching the reference app's `MaxGYR`
    /// default (`OverworldRouteDrawing.fs:94`/`:28`).
    private static let maxGYR = 12

    /// The marked any-road (warp) screens, from live map state (T-015.5).
    /// Two or more marked any-roads warp between each other in the routing
    /// graph (cost 4), so hover routing can use them.
    private var anyRoadDestinations: [(x: Int, y: Int)] {
        mapState.anyRoadLocations.compactMap { $0 }.map { (x: $0.x, y: $0.y) }
    }

    private var dynamicGraph: OverworldDynamicGraph? {
        OverworldRoutingGraph.dynamicGraph(
            ladder: playerState.haveLadder,
            raft: playerState.haveRaft,
            // Recorder-warp destinations depend on the recorder-dest
            // derivation (recorder options + HDN + the T-018 orchestration),
            // not yet ported — see docs/domain.md § 6 (T-015 follow-ons).
            recorderWarpDestinations: [],
            anyRoads: anyRoadDestinations,
            isMirror: Self.placeholderIsMirror,
            canScreenScroll: options.showScreenScrolls
        )
    }

    private var highlightByCoordinate: [OverworldScreenCoordinate: Bool] {
        guard let routeHighlight else { return [:] }
        return Dictionary(uniqueKeysWithValues: routeHighlight.highlightedTiles.map { ($0.coordinate, $0.isBold) })
    }

    /// The terrain instance for the current quest — supplies `sometimesEmpty`
    /// for the yellow GYR tint.
    private var overworldInstance: OverworldInstance {
        OverworldInstance(quest: quest)
    }

    /// The green/yellow/red tint for a highlighted screen (T-015.4).
    /// A "dead spot" (no potential opening) — vanilla map only. A custom map (T-167)
    /// has none, so every screen stays clickable/markable there.
    private func screenIsDeadSpot(_ column: Int, _ row: Int) -> Bool {
        customMapImagePath == nil && overworldInstance.alwaysEmpty(x: column, y: row)
    }

    private func gyrColor(column: Int, row: Int, mark: OverworldTileMark) -> Color {
        switch OverworldRouteTint.forHighlightedTile(
            markRawIndex: mark.rawIndex,
            gettable: mapState.owGettableLocations[column, row],
            sometimesEmpty: overworldInstance.sometimesEmpty(x: column, y: row)
        ) {
        case .green: .green
        case .yellow: .yellow
        case .red: .red
        }
    }

    var body: some View {
        let _ = perfTrace()
        GeometryReader { geometry in
            let tileWidth = geometry.size.width / CGFloat(OverworldGrid.columnCount)
            let tileHeight = tileWidth / tileAspectRatio
            let highlights = highlightByCoordinate

            ZStack(alignment: .topLeading) {
                // Custom map (T-167): draw the imported image ONCE, stretched across the
                // whole 16×8 grid, rather than slicing 128 per-screen crops. Slicing
                // assumed the image was an exact multiple of 16×8 screens at the NES
                // 256:176 aspect; anything else got integer-truncated (`width / 16`
                // drops the remainder, so every column drifted left) and then
                // aspect-fill-cropped inside each tile — which is what made imported
                // maps render zoomed and misaligned. One stretch puts screen N on cell
                // N by construction, whatever the source resolution or aspect.
                if let path = customMapImagePath, let image = CustomMapImage.full(path) {
                    Image(decorative: image, scale: 1, orientation: .up)
                        .resizable()
                        .frame(width: tileWidth * CGFloat(OverworldGrid.columnCount),
                               height: tileHeight * CGFloat(OverworldGrid.rowCount))
                }
                VStack(spacing: 0) {
                    ForEach(0..<OverworldGrid.rowCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<OverworldGrid.columnCount, id: \.self) { column in
                                let mark = grid.mark(column: column, row: row)
                                // Custom-map mode (T-167): the imported image supplies the
                                // per-screen background and fog gates its visibility.
                                let customActive = customMapImagePath != nil
                                // On a custom map the terrain comes from the single
                                // stretched image behind this grid, so tiles draw no
                                // background of their own (see the ZStack above).
                                let background = customActive
                                    ? nil
                                    : OverworldBackgroundAtlas.tile(quest: quest, column: column, row: row)
                                let fog = customActive && !grid.isCustomMapRevealed(column: column, row: row)
                                // On a custom map the quest's *openings* are meaningless — every
                                // screen is markable (no dead spots) and the vanilla fixed fairy
                                // spots don't apply; fairies are placed by hand instead (T-167).
                                // The chosen quest still drives secrets/door-repair logic.
                                let isAlwaysEmpty = screenIsDeadSpot(column, row)
                                let showsFairy = customActive
                                    ? grid.isCustomFairy(column: column, row: row)
                                    : (isAlwaysEmpty && OverworldFairySpots.isFairySpot(column: column, row: row, quest: quest))
                                // Dim = claimed ("used") OR a permanently-dimmed
                                // mark (door repair — one-shot, never revisited).
                                // The latter derives from the mark, so a groundhog
                                // reset (clears only `used`) keeps it dimmed.
                                // Armos / White-Sword-Item cave / Magical-Sword cave
                                // instead derive their dim from model state — the
                                // item behind them being collected — not a map
                                // toggle (T-110, matching the reference tile dim).
                                let used = tileIsCollected(mark: mark, column: column, row: row)
                                let shopSecondItem = grid.shopSecondItem(column: column, row: row)
                                let dungeonDone: Bool = { if case .dungeon(let n) = mark { return dungeonComplete(n) } else { return false } }()
                                let kindHidden = OverworldTileHiding.isKindHidden(mark: mark, options: options, hasRescuedZelda: hasRescuedZelda)
                                TileView(mark: mark, background: background, tileWidth: tileWidth, tileHeight: tileHeight, isAlwaysEmpty: isAlwaysEmpty, showsFairy: showsFairy, mirrored: mirrored, hideDungeonNumbers: hideDungeonNumbers, used: used, shopSecondItem: shopSecondItem, hideMarks: overlays?.isActive(.hideMarks) ?? false, dungeonComplete: dungeonDone, kindHidden: kindHidden, fog: fog, sharedBackground: customActive)
                                    .overlay {
                                        if options.highlightNearby, !customActive, !isAlwaysEmpty,
                                           let isBold = highlights[OverworldScreenCoordinate(x: column, y: row)] {
                                            // True GYR (T-015.4): green = accessible, yellow =
                                            // sometimes-empty, red = inaccessible, per the
                                            // reference's doComputedDrawing cascade. Bold/pale is
                                            // the reachability `isBold` axis, rendered as opacity.
                                            Rectangle().fill(gyrColor(column: column, row: row, mark: mark).opacity(isBold ? 0.45 : 0.2))
                                        }
                                    }
                                    .overlay {
                                        // Top-section overlay toggles (T-035.2): open-caves /
                                        // money highlights, previewed on hover / locked on click.
                                        if !isAlwaysEmpty, let color = overlayHighlight(column: column, row: row, mark: mark) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .strokeBorder(color, lineWidth: 2)
                                                .background(RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.18)))
                                        }
                                    }
                                    .overlay {
                                        // Zones (T-035.3): tint each screen by its overworld region.
                                        if overlays?.isActive(.zones) == true {
                                            Rectangle().fill(OverworldZones.color(column: column, row: row).opacity(0.4))
                                        }
                                    }
                                    .overlay {
                                        // Coords (T-035.3): the screen's A1…H16 coordinate.
                                        if overlays?.isActive(.coords) == true {
                                            Text(OverworldCoords.label(column: column, row: row))
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black, radius: 1)
                                                .padding(1)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                // Counter-flip so the coord reads normally under a
                                                // mirrored map (it still marks its true screen).
                                                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                                        }
                                    }
                                    .overlay {
                                        // Recorder-warp destination marker (T-035.7): a lone cyan
                                        // diamond on the *current* destination screen only.
                                        if !isAlwaysEmpty,
                                           recorderDestination == OverworldScreenCoordinate(x: column, y: row) {
                                            Rectangle()
                                                .fill(Color.cyan)
                                                .frame(width: tileHeight * 0.24, height: tileHeight * 0.24)
                                                .rotationEffect(.degrees(45))
                                                .overlay(Rectangle().stroke(.black, lineWidth: 0.5).rotationEffect(.degrees(45)))
                                                .padding(2)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                                        }
                                    }
                                    .overlay {
                                        // Start-spot marker (T-035.8): a lime ring on a violet
                                        // glow, centered on the player's spawn screen.
                                        if startSpot == OverworldScreenCoordinate(x: column, y: row) {
                                            Circle()
                                                .stroke(Color(red: 0.58, green: 0, blue: 0.83), lineWidth: 4)
                                                .overlay(Circle().stroke(Color(red: 0.5, green: 1, blue: 0), lineWidth: 2))
                                                .frame(width: tileHeight * 0.62, height: tileHeight * 0.62)
                                                .shadow(color: Color(red: 0.58, green: 0, blue: 0.83), radius: 2)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .allowsHitTesting(false)
                                        }
                                        // Custom waypoint (T-162): an amber diamond, visually
                                        // distinct from the violet start-spot ring.
                                        if customWaypoint == OverworldScreenCoordinate(x: column, y: row) {
                                            Rectangle()
                                                .stroke(Color(red: 1, green: 0.72, blue: 0.1), lineWidth: 3)
                                                .rotationEffect(.degrees(45))
                                                .frame(width: tileHeight * 0.44, height: tileHeight * 0.44)
                                                .shadow(color: Color(red: 1, green: 0.72, blue: 0.1), radius: 2)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                    .overlay {
                                        // Enemy annotations (T-117): up to two small
                                        // sprites **stacked vertically** along the left
                                        // edge (T-118) so they don't cover the tile's
                                        // own mark icon; counter-flipped under a mirror.
                                        let enemies = grid.enemies(column: column, row: row)
                                        if !enemies.isEmpty {
                                            VStack(spacing: 1) {
                                                ForEach(Array(enemies.enumerated()), id: \.offset) { _, enemy in
                                                    OverworldEnemyGlyph(enemy: enemy, size: tileHeight * 0.30)
                                                }
                                            }
                                            .padding(1)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                                            .allowsHitTesting(false)
                                        }
                                    }
                                    .overlay {
                                        // Keyboard cursor (T-134): a bright ring on the
                                        // cursor tile while the cursor is on the overworld.
                                        if focus.cursorShown, focus.cursorRegion == .overworld,
                                           focus.overworldCursor == .init(col: column, row: row) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .strokeBorder(Color.cyan, lineWidth: 2)
                                                .shadow(color: .cyan, radius: 2)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                    .onTapGesture { handleLeftClick(column: column, row: row) }
                                    // In-place item prompt for Armos / White-Sword cave (T-106).
                                    .popover(isPresented: itemPromptBinding(column: column, row: row), arrowEdge: .trailing) {
                                        if let p = itemPrompt {
                                            BoxItemPicker(box: p.isArmos ? dungeonTracker.armosBox : dungeonTracker.sword2Box,
                                                          instance: dungeonTracker, iconOptions: iconOptions) { itemPrompt = nil }
                                                .padding(4)
                                        }
                                    }
                                    // The tile chooser + enemy picker (T-185), bundled into one
                                    // modifier so the tile expression stays type-checkable.
                                    .modifier(tileChooserModifiers(column: column, row: row))
                                    .onContinuousHover { phase in
                                        handleHover(column: column, row: row, phase: phase, tileWidth: tileWidth, tileHeight: tileHeight)
                                    }
                                    // Always-empty screens can never contain anything, so they
                                    // are permanent "don't care" and take no input (the reference
                                    // makes them a non-interactive opaque layer).
                                    .allowsHitTesting(!isAlwaysEmpty)
                                    // Custom-drawn tiles (Rectangle + onTapGesture) have NO
                                    // accessibility representation by default -- confirmed by
                                    // inspecting the accessibility tree while testing this view,
                                    // not assumed. VoiceOver users could not otherwise perceive
                                    // or activate any of these 128 tiles. See docs/ux.md
                                    // "Accessibility baseline" -- this is the first view with
                                    // fully custom interactive elements, so it's handled here
                                    // rather than deferred again.
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("Overworld tile, column \(column + 1), row \(row + 1)")
                                    .accessibilityValue(isAlwaysEmpty ? "Always empty (nothing here)" : mark.displayName)
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityAction { handleLeftClick(column: column, row: row) }
                            }
                        }
                    }
                }
                if options.drawRoutes, let routeHighlight {
                    OverworldRouteLinesOverlay(lines: routeHighlight.lines, tileWidth: tileWidth, tileHeight: tileHeight)
                        .allowsHitTesting(false)
                }
            }
            // Mirror the whole map East↔West (T-047). scaleEffect flips both the
            // rendering and the hit-test coordinate space, so taps still land on
            // the correct (mirrored) tile; per-tile glyphs are counter-flipped
            // inside `TileView` / the coords overlay so they stay readable.
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        }
        .aspectRatio(tileAspectRatio * CGFloat(OverworldGrid.columnCount) / CGFloat(OverworldGrid.rowCount), contentMode: .fit)
    }

    /// Hover-triggered route computation, ported structurally from the
    /// reference app's mouse-move-driven `drawPathsImpl` calls
    /// (`Z1R_Avalonia/UI.fs:80-94`) — recomputed on every hover update just
    /// as the reference recomputes on every mouse move, since the graph is
    /// small enough (~140 vertices) for this to be cheap.
    private func handleHover(column: Int, row: Int, phase: HoverPhase, tileWidth: CGFloat, tileHeight: CGFloat) {
        // The keyboard cursor follows the mouse (T-134) — track the hovered tile
        // regardless of the routing/highlight options below.
        if case .active = phase, !screenIsDeadSpot(column, row) {
            PerfLog.hover("HOVER overworld (\(column),\(row))")
            focus.hoverOverworld(col: column, row: row)
        } else if case .ended = phase {
            focus.endHover(.overworld)
        }
        // Routing/GYR is derived from the vanilla map's openings — meaningless on a
        // custom map, so skip it entirely there (T-167).
        guard customMapImagePath == nil, options.drawRoutes || options.highlightNearby else {
            hoveredVertex = nil
            routeHighlight = nil
            return
        }
        switch phase {
        case .active(let location):
            guard
                let graph = dynamicGraph,
                let screenType = graph.screenTypes[OverworldScreenCoordinate(x: column, y: row)]
            else { return }
            let portion: OverworldScreenPortion
            switch screenType {
            case .whole: portion = .full
            case .northSouth: portion = location.y > tileHeight / 2 ? .south : .north
            case .eastWest: portion = location.x > tileWidth / 2 ? .east : .west
            }
            let vertex = OverworldVertex(column, row, portion)
            guard vertex != hoveredVertex else { return }
            hoveredVertex = vertex

            var unmarkedScreens: Set<OverworldScreenCoordinate> = []
            for gridRow in 0..<OverworldGrid.rowCount {
                for gridColumn in 0..<OverworldGrid.columnCount where grid.mark(column: gridColumn, row: gridRow) == .unmarked {
                    unmarkedScreens.insert(OverworldScreenCoordinate(x: gridColumn, y: gridRow))
                }
            }
            routeHighlight = OverworldRoutingGraph.routeHighlight(
                from: vertex,
                unmarkedScreens: unmarkedScreens,
                screenTypes: graph.screenTypes,
                adjacency: graph.adjacency,
                maxBold: options.highlightNearby ? Self.maxGYR : 0,
                maxPale: options.highlightNearby ? Self.maxGYR : 0
            )
        case .ended:
            hoveredVertex = nil
            routeHighlight = nil
        }
    }

    private func handleLeftClick(column: Int, row: Int) {
        // Always-empty screens are permanent "don't care" and never editable
        // (defensive — the tile also sets `.allowsHitTesting(false)`).
        if screenIsDeadSpot(column, row) { return }
        // "LC unmarked → mark dark" (docs/domain.md § 4.5). Left-click on an
        // already-dark tile is handled by the context menu, matching "LC
        // dark tile ... → popup" — SwiftUI's contextMenu also responds to a
        // plain click when attached this way is avoided by only mutating
        // state here for the unmarked case.
        let mark = grid.mark(column: column, row: row)
        if mark == .unmarked {
            grid.setMark(.dontCare, column: column, row: row)
        } else if mark == .dontCare {
            // "LC dark tile → popup" (docs/domain.md § 4.5): a second left-click on a
            // Don't-Care tile opens the tile chooser (T-185). Graphical mode → the icon
            // grid; menu mode → the **native** NSMenu (chrome-identical to right-click).
            if options.graphicalOverworldChooser {
                chooserCell = TileCoord(column: column, row: row)
            } else {
                showNativeMarkMenu(column: column, row: row)
            }
        } else if mark == .takeAny {
            // A take-any tile cycles its claimed version (untaken → heart →
            // potion → candle), kept in sync with its Items-group slot (T-066).
            onCycleTakeAny(column, row)
        } else if case .swordCave(3) = mark {
            // The Magical-Sword cave isn't a manual `used` toggle — its dim derives
            // from whether the player has the magical sword. Clicking it "takes" the
            // magical sword (or un-takes it), which in turn dims/brightens the tile
            // (T-119, user request).
            onMagicalSwordCaveUsedChanged(playerState.swordLevel < 3)
        } else if mark.isUsedToggleable {
            // A claimable tile (secret / letter / hint shop / wood-sword cave):
            // left-click toggles it used ⇄ unused (T-054).
            grid.toggleUsed(column: column, row: row)
            // Marking the wood-sword cave "used" grants (or ungrants) the wood
            // sword — the cave is where you collect it (T-118, user request).
            if case .swordCave(1) = mark {
                onWoodSwordCaveUsedChanged(grid.isUsed(column: column, row: row))
            }
        }
    }

    /// Whether a tile should render dimmed ("collected"). Most marks use the map's
    /// own manual `used` toggle (plus the permanently-dim door-repair). The three
    /// item-bearing caves derive it from model state instead (T-110), matching the
    /// reference: armos → `armosBox.isDone`, White-Sword-Item cave (SWORD2) →
    /// `sword2Box.isDone`, Magical-Sword cave (SWORD3) → player has the magical
    /// sword (`swordLevel == 3`).
    private func tileIsCollected(mark: OverworldTileMark, column: Int, row: Int) -> Bool {
        switch mark {
        case .armos: return dungeonTracker.armosBox.isDone
        case .swordCave(2): return dungeonTracker.sword2Box.isDone
        case .swordCave(3): return playerState.swordLevel >= 3
        // The letter's dim is inverted (T-118): it renders dark while you *hold* the
        // potion letter (not yet used, `extraData == 0`) and brightens once you've
        // used/delivered it — matching the reference letter tile.
        case .theLetter: return !grid.isUsed(column: column, row: row)
        default:
            return grid.isUsed(column: column, row: row) || mark.dimsPermanentlyWhenMarked
        }
    }

    /// Per-cell binding for the in-place item prompt popover (T-106).
    private func itemPromptBinding(column: Int, row: Int) -> Binding<Bool> {
        Binding(
            get: { itemPrompt?.column == column && itemPrompt?.row == row },
            set: { if !$0 { itemPrompt = nil } }
        )
    }

    /// Per-cell presentation bindings for the tile chooser and enemy-picker popovers
    /// (T-185): only the matching tile shows the popover (the state is one shared cell).
    private func chooserPresented(column: Int, row: Int) -> Binding<Bool> {
        Binding(get: { chooserCell == TileCoord(column: column, row: row) },
                set: { if !$0 { chooserCell = nil } })
    }
    private func enemyPresented(column: Int, row: Int) -> Binding<Bool> {
        Binding(get: { enemyCell == TileCoord(column: column, row: row) },
                set: { if !$0 { enemyCell = nil } })
    }

    /// Bundles the tile's chooser + enemy-picker behavior (T-185) into a single
    /// modifier, keeping the per-tile view expression small enough to type-check.
    private func tileChooserModifiers(column: Int, row: Int) -> TileChooserModifiers {
        TileChooserModifiers(
            graphical: options.graphicalOverworldChooser,
            onOpenChooser: { chooserCell = TileCoord(column: column, row: row) },
            menu: { AnyView(markMenu(column: column, row: row)) },
            chooserPresented: chooserPresented(column: column, row: row),
            chooser: { AnyView(chooserPopover(column: column, row: row)) },
            onScrollUp: { enemyCell = TileCoord(column: column, row: row) },
            enemyPresented: enemyPresented(column: column, row: row),
            enemy: {
                AnyView(OverworldEnemyPicker(
                    current: grid.enemies(column: column, row: row),
                    onToggle: { grid.toggleEnemy($0, column: column, row: row) },
                    onClear: { grid.toggleEnemy(.unmarked, column: column, row: row) },
                    onDone: { enemyCell = nil }))
            })
    }

    /// The tile chooser popover body — the graphical icon grid (T-185). Only presented
    /// in graphical mode; menu mode opens the native `NSMenu` instead (`showNativeMarkMenu`).
    private func chooserPopover(column: Int, row: Int) -> some View {
        GraphicalTileChooser(
            currentMark: grid.mark(column: column, row: row),
            isStartSpot: startSpot == OverworldScreenCoordinate(x: column, y: row),
            hideDungeonNumbers: hideDungeonNumbers,
            isExhausted: { isExhausted($0, column: column, row: row, counts: markCounts) },
            onPick: { action in
                switch action {
                case .mark(.shop(let kind))
                    where OverworldMark.applyShopHotkeySmart(kind, column: column, row: row, grid: grid):
                    // Already a shop → the second shop pick fills the 2nd-item slot,
                    // a third replaces the primary (T-185, same smarts as the shop hotkey).
                    break
                case .mark(let m): applyMark(m, column: column, row: row)
                case .takeAny(let s): applyTakeAny(s, column: column, row: row)
                case .startSpot: onSetStartSpot(column, row)
                }
                chooserCell = nil
            })
    }

    /// Set a tile's mark from the picker. A claimable mark (secret / take-any /
    /// armos / letter / hint shop) defaults to **used** — you usually mark one
    /// right after collecting it; a left-click flips it back to unused (T-056).
    private func applyMark(_ mark: OverworldTileMark, column: Int, row: Int) {
        // Selecting a mark closes the menu-mode chooser popover (T-185) — a picked
        // mark should dismiss it, like the native context menu does on selection.
        chooserCell = nil
        // Grid mechanics live in the shared apply (T-134) so a keyboard hotkey on
        // the cursor cell does identically the same thing as this click path.
        let result = OverworldMark.apply(mark, column: column, row: row, grid: grid,
                                         releaseTakeAny: onReleaseTakeAny,
                                         placeDungeon: onPlaceDungeon)
        // Overworld-overwrite reminder (T-096): warn on a destructive change of a
        // real mark, in case it was accidental.
        onOverwrite(result.oldMark, mark, column, row)
        // In-place item prompt (T-106): marking an Armos or the White-Sword-Item
        // cave immediately asks what item was there. A slight delay lets the context
        // menu finish dismissing before the popover opens.
        if let isArmos = result.itemPromptIsArmos {
            DispatchQueue.main.async {
                presentPopoverWithoutAnimation { itemPrompt = .init(column: column, row: row, isArmos: isArmos) }
            }
        }
    }

    /// Mark a take-any cave and record what was taken (T-057/T-066). Delegated
    /// to the model so the tile's linked Items-group heart slot stays in sync:
    /// the tile reuses its own slot when re-marked, and `.untaken` frees it.
    private func applyTakeAny(_ state: TakeAnyHeartState, column: Int, row: Int) {
        chooserCell = nil   // dismiss the menu-mode chooser popover on selection (T-185)
        onSetTakeAny(state, column, row)
    }

    /// Count of each mark across the grid — for disabling exhausted picker
    /// options (T-058).
    private var markCounts: [OverworldTileMark: Int] {
        var counts: [OverworldTileMark: Int] = [:]
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                counts[grid.mark(column: c, row: r), default: 0] += 1
            }
        }
        return counts
    }

    /// Whether placing `mark` at this tile would exceed its per-quest max — i.e.
    /// its option should be disabled. The current tile's own mark doesn't count
    /// against the limit (re-selecting it is a no-op).
    private func isExhausted(_ mark: OverworldTileMark, column: Int, row: Int, counts: [OverworldTileMark: Int]) -> Bool {
        let current = grid.mark(column: column, row: row)
        let otherCount = (counts[mark] ?? 0) - (current == mark ? 1 : 0)
        return otherCount >= OverworldTileLimits.maxUses(mark, quest: quest)
    }

    /// Whether **every** mark in a submenu is exhausted — disables the parent
    /// menu itself (T-059), e.g. "Dungeon" once all nine are placed.
    private func allExhausted(_ marks: [OverworldTileMark], column: Int, row: Int, counts: [OverworldTileMark: Int]) -> Bool {
        marks.allSatisfy { isExhausted($0, column: column, row: row, counts: counts) }
    }

    /// The Shop submenu (+ its "2nd item" submenu once a shop is marked, T-060).
    /// Extracted so "Shops before dungeons" can place it at the top of the popup
    /// or in its default spot (T-004.2).
    @ViewBuilder
    private func shopMenus(column: Int, row: Int) -> some View {
        Menu("Shop") {
            ForEach(ShopKind.allCases, id: \.self) { kind in
                Button(kind.shortName) { applyMark(.shop(kind), column: column, row: row) }
            }
        }
        // A shop tile carries two items (T-060) — its second item is set here.
        if case .shop(let item1) = grid.mark(column: column, row: row) {
            Menu("Shop — 2nd item") {
                Button("None") { grid.setShopSecondItem(nil, column: column, row: row) }
                ForEach(ShopKind.allCases, id: \.self) { kind in
                    Button(kind.shortName) { grid.setShopSecondItem(kind, column: column, row: row) }
                        .disabled(kind == item1) // no duplicate item
                }
            }
        }
    }

    @ViewBuilder
    private func markMenu(column: Int, row: Int) -> some View {
        let counts = markCounts
        Button("Clear (unmarked)") { applyMark(.unmarked, column: column, row: row) }
        Button("Don't care") { applyMark(.dontCare, column: column, row: row) }
        Divider()
        // "Shops before dungeons" (Overworld.ShopsFirst): the popup starts with
        // shops when on, dungeons when off (OptionsMenu.fs:49).
        if options.shopsBeforeDungeons { shopMenus(column: column, row: row) }
        Menu(DungeonLabeling.columnWord(prefix: options.levelPrefix).capitalized) {
            ForEach(1...9, id: \.self) { number in
                // Reflect the user's dungeon naming (T-112): LEVEL-N / BOARD-N, or
                // LEVEL-A…H under HDN. The mark still stores the slot number, so
                // located-linking is unchanged.
                let label = DungeonLabeling.columnName(
                    slot: number, prefix: options.levelPrefix,
                    hideDungeonNumbers: hideDungeonNumbers)
                Button(label) {
                    applyMark(.dungeon(number), column: column, row: row)
                }
                .disabled(isExhausted(.dungeon(number), column: column, row: row, counts: counts))
            }
        }
        .disabled(allExhausted((1...9).map { .dungeon($0) }, column: column, row: row, counts: counts))
        Menu("Any road") {
            ForEach(1...4, id: \.self) { number in
                Button("Any road \(number)") { applyMark(.anyRoad(number), column: column, row: row) }
                    .disabled(isExhausted(.anyRoad(number), column: column, row: row, counts: counts))
            }
            // "?" — a warp cave whose 1–4 order isn't known yet (T-181). Not
            // exhaustion-limited: you may mark several before assigning numbers.
            Button("Any road (?)") { applyMark(.anyRoad(0), column: column, row: row) }
        }
        Menu("Sword cave") {
            ForEach(1...3, id: \.self) { number in
                Button(Self.swordCaveLabel(number)) {
                    applyMark(.swordCave(number), column: column, row: row)
                }
                .disabled(isExhausted(.swordCave(number), column: column, row: row, counts: counts))
            }
        }
        .disabled(allExhausted((1...3).map { .swordCave($0) }, column: column, row: row, counts: counts))
        if !options.shopsBeforeDungeons { shopMenus(column: column, row: row) }
        Menu("Secret") {
            ForEach(SecretSize.allCases, id: \.self) { size in
                Button(size.displayName) { applyMark(.secret(size), column: column, row: row) }
                    .disabled(isExhausted(.secret(size), column: column, row: row, counts: counts))
            }
        }
        // Take-any is a submenu (Unclaimed / Potion / Blue candle / Heart since
        // T-057), so it belongs with the other submenus rather than down among
        // the one-shot marks where it used to live as a plain button (T-063).
        Menu("Take any") {
            Button("Unclaimed") { applyTakeAny(.untaken, column: column, row: row) }
            Button("Potion") { applyTakeAny(.takenPotion, column: column, row: row) }
            Button("Blue candle") { applyTakeAny(.takenCandle, column: column, row: row) }
            Button("Heart") { applyTakeAny(.takenHeart, column: column, row: row) }
        }
        .disabled(isExhausted(.takeAny, column: column, row: row, counts: counts))
        Divider()
        Button("Door repair") { applyMark(.doorRepair, column: column, row: row) }
            .disabled(isExhausted(.doorRepair, column: column, row: row, counts: counts))
        Button("Money making game") { applyMark(.moneyMakingGame, column: column, row: row) }
            .disabled(isExhausted(.moneyMakingGame, column: column, row: row, counts: counts))
        Button("The letter") { applyMark(.theLetter, column: column, row: row) }
            .disabled(isExhausted(.theLetter, column: column, row: row, counts: counts))
        Button("Armos") { applyMark(.armos, column: column, row: row) }
            .disabled(isExhausted(.armos, column: column, row: row, counts: counts))
        Button("Hint shop") { applyMark(.hintShop, column: column, row: row) }
            .disabled(isExhausted(.hintShop, column: column, row: row, counts: counts))
        Button("Potion shop") { applyMark(.potionShop, column: column, row: row) }
            .disabled(isExhausted(.potionShop, column: column, row: row, counts: counts))
        // Custom-map fairy fountains (T-167): vanilla fairy spots are fixed map truth,
        // but a custom map has none, so they're hand-placed. It belongs with the other
        // "what's on this screen" marks rather than down with the fog utilities.
        if customMapImagePath != nil {
            Button(grid.isCustomFairy(column: column, row: row) ? "Remove fairy fountain" : "Place fairy fountain") {
                grid.toggleCustomFairy(column: column, row: row)
            }
        }
        Divider()
        // Enemies (T-117): an up-to-two enemy annotation from the reduced overworld
        // set, independent of the tile's mark. Each pick toggles; reopen to add a
        // second (context menus dismiss on selection).
        Menu("Enemies") {
            let current = grid.enemies(column: column, row: row)
            ForEach(Array(MonsterDetail.overworldEnemies.enumerated()), id: \.offset) { _, enemy in
                Button {
                    grid.toggleEnemy(enemy, column: column, row: row)
                } label: {
                    if current.contains(enemy) { Label(enemy.displayName, systemImage: "checkmark") }
                    else { Text(enemy.displayName) }
                }
            }
            if !current.isEmpty {
                Divider()
                Button("Clear enemies") { grid.toggleEnemy(.unmarked, column: column, row: row) }
            }
        }
        Divider()
        // Start spot (T-035.8): a placeable spawn-screen marker, independent of
        // the tile's mark.
        if startSpot == OverworldScreenCoordinate(x: column, y: row) {
            Button("Clear start spot") { onClearStartSpot() }
        } else {
            Button("Set as start spot") { onSetStartSpot(column, row) }
        }
        // Custom waypoint (T-162): a second, freely-placeable personal marker.
        if customWaypoint == OverworldScreenCoordinate(x: column, y: row) {
            Button("Clear waypoint") { onClearWaypoint() }
        } else {
            Button("Set waypoint") { onSetWaypoint(column, row) }
        }
        // Custom-map fog (T-167): manually reveal/re-hide a screen without marking it.
        if customMapImagePath != nil {
            Divider()
            if grid.isCustomMapRevealed(column: column, row: row) {
                Button("Re-hide screen (fog)") { grid.setCustomMapRevealed(false, column: column, row: row) }
            } else {
                Button("Reveal screen") { grid.setCustomMapRevealed(true, column: column, row: row) }
            }
        }
    }

    // MARK: Native context menu (double-left-click on a Don't-Care tile, T-185)

    /// A menu item backed by a Swift closure (see `ClosureMenuTarget`).
    private func nsItem(_ title: String, enabled: Bool = true, checked: Bool = false,
                        _ action: @escaping () -> Void) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(ClosureMenuTarget.fire), keyEquivalent: "")
        let target = ClosureMenuTarget(action)
        item.target = target
        item.representedObject = target   // retain (item.target is weak)
        item.isEnabled = enabled
        item.state = checked ? .on : .off
        return item
    }

    /// A submenu item; its child menu is built by `build`.
    private func nsSubmenu(_ title: String, enabled: Bool = true, _ build: (NSMenu) -> Void) -> NSMenuItem {
        let sub = NSMenu(title: title)
        sub.autoenablesItems = false
        build(sub)
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = sub
        item.isEnabled = enabled
        return item
    }

    /// The AppKit twin of `markMenu` — a real `NSMenu`, so the double-left-click menu
    /// is chrome-identical to the native right-click menu (T-185). **Keep in sync with
    /// `markMenu`.**
    private func makeMarkNSMenu(column: Int, row: Int) -> NSMenu {
        let counts = markCounts
        let menu = NSMenu()
        menu.autoenablesItems = false

        menu.addItem(nsItem("Clear (unmarked)") { applyMark(.unmarked, column: column, row: row) })
        menu.addItem(nsItem("Don't care") { applyMark(.dontCare, column: column, row: row) })
        menu.addItem(.separator())

        func addShops() {
            menu.addItem(nsSubmenu("Shop") { sub in
                for kind in ShopKind.allCases {
                    sub.addItem(nsItem(kind.shortName) { applyMark(.shop(kind), column: column, row: row) })
                }
            })
            if case .shop(let item1) = grid.mark(column: column, row: row) {
                menu.addItem(nsSubmenu("Shop — 2nd item") { sub in
                    sub.addItem(nsItem("None") { grid.setShopSecondItem(nil, column: column, row: row) })
                    for kind in ShopKind.allCases {
                        sub.addItem(nsItem(kind.shortName, enabled: kind != item1) {
                            grid.setShopSecondItem(kind, column: column, row: row)
                        })
                    }
                })
            }
        }

        if options.shopsBeforeDungeons { addShops() }

        menu.addItem(nsSubmenu(DungeonLabeling.columnWord(prefix: options.levelPrefix).capitalized,
                               enabled: !allExhausted((1...9).map { .dungeon($0) }, column: column, row: row, counts: counts)) { sub in
            for number in 1...9 {
                let label = DungeonLabeling.columnName(slot: number, prefix: options.levelPrefix,
                                                       hideDungeonNumbers: hideDungeonNumbers)
                sub.addItem(nsItem(label, enabled: !isExhausted(.dungeon(number), column: column, row: row, counts: counts)) {
                    applyMark(.dungeon(number), column: column, row: row)
                })
            }
        })
        menu.addItem(nsSubmenu("Any road") { sub in
            for number in 1...4 {
                sub.addItem(nsItem("Any road \(number)", enabled: !isExhausted(.anyRoad(number), column: column, row: row, counts: counts)) {
                    applyMark(.anyRoad(number), column: column, row: row)
                })
            }
            sub.addItem(nsItem("Any road (?)") { applyMark(.anyRoad(0), column: column, row: row) })
        })
        menu.addItem(nsSubmenu("Sword cave",
                               enabled: !allExhausted((1...3).map { .swordCave($0) }, column: column, row: row, counts: counts)) { sub in
            for number in 1...3 {
                sub.addItem(nsItem(Self.swordCaveLabel(number), enabled: !isExhausted(.swordCave(number), column: column, row: row, counts: counts)) {
                    applyMark(.swordCave(number), column: column, row: row)
                })
            }
        })
        if !options.shopsBeforeDungeons { addShops() }
        menu.addItem(nsSubmenu("Secret") { sub in
            for size in SecretSize.allCases {
                sub.addItem(nsItem(size.displayName, enabled: !isExhausted(.secret(size), column: column, row: row, counts: counts)) {
                    applyMark(.secret(size), column: column, row: row)
                })
            }
        })
        menu.addItem(nsSubmenu("Take any", enabled: !isExhausted(.takeAny, column: column, row: row, counts: counts)) { sub in
            sub.addItem(nsItem("Unclaimed") { applyTakeAny(.untaken, column: column, row: row) })
            sub.addItem(nsItem("Potion") { applyTakeAny(.takenPotion, column: column, row: row) })
            sub.addItem(nsItem("Blue candle") { applyTakeAny(.takenCandle, column: column, row: row) })
            sub.addItem(nsItem("Heart") { applyTakeAny(.takenHeart, column: column, row: row) })
        })
        menu.addItem(.separator())

        menu.addItem(nsItem("Door repair", enabled: !isExhausted(.doorRepair, column: column, row: row, counts: counts)) { applyMark(.doorRepair, column: column, row: row) })
        menu.addItem(nsItem("Money making game", enabled: !isExhausted(.moneyMakingGame, column: column, row: row, counts: counts)) { applyMark(.moneyMakingGame, column: column, row: row) })
        menu.addItem(nsItem("The letter", enabled: !isExhausted(.theLetter, column: column, row: row, counts: counts)) { applyMark(.theLetter, column: column, row: row) })
        menu.addItem(nsItem("Armos", enabled: !isExhausted(.armos, column: column, row: row, counts: counts)) { applyMark(.armos, column: column, row: row) })
        menu.addItem(nsItem("Hint shop", enabled: !isExhausted(.hintShop, column: column, row: row, counts: counts)) { applyMark(.hintShop, column: column, row: row) })
        menu.addItem(nsItem("Potion shop", enabled: !isExhausted(.potionShop, column: column, row: row, counts: counts)) { applyMark(.potionShop, column: column, row: row) })
        if customMapImagePath != nil {
            let isFairy = grid.isCustomFairy(column: column, row: row)
            menu.addItem(nsItem(isFairy ? "Remove fairy fountain" : "Place fairy fountain") { grid.toggleCustomFairy(column: column, row: row) })
        }
        menu.addItem(.separator())

        let currentEnemies = grid.enemies(column: column, row: row)
        menu.addItem(nsSubmenu("Enemies") { sub in
            for enemy in MonsterDetail.overworldEnemies {
                sub.addItem(nsItem(enemy.displayName, checked: currentEnemies.contains(enemy)) {
                    grid.toggleEnemy(enemy, column: column, row: row)
                })
            }
            if !currentEnemies.isEmpty {
                sub.addItem(.separator())
                sub.addItem(nsItem("Clear enemies") { grid.toggleEnemy(.unmarked, column: column, row: row) })
            }
        })
        menu.addItem(.separator())

        if startSpot == OverworldScreenCoordinate(x: column, y: row) {
            menu.addItem(nsItem("Clear start spot") { onClearStartSpot() })
        } else {
            menu.addItem(nsItem("Set as start spot") { onSetStartSpot(column, row) })
        }
        if customWaypoint == OverworldScreenCoordinate(x: column, y: row) {
            menu.addItem(nsItem("Clear waypoint") { onClearWaypoint() })
        } else {
            menu.addItem(nsItem("Set waypoint") { onSetWaypoint(column, row) })
        }
        if customMapImagePath != nil {
            menu.addItem(.separator())
            if grid.isCustomMapRevealed(column: column, row: row) {
                menu.addItem(nsItem("Re-hide screen (fog)") { grid.setCustomMapRevealed(false, column: column, row: row) })
            } else {
                menu.addItem(nsItem("Reveal screen") { grid.setCustomMapRevealed(true, column: column, row: row) })
            }
        }
        return menu
    }

    /// Pop up the native mark menu at the cursor (double-left-click on a Don't-Care
    /// tile in menu mode, T-185).
    private func showNativeMarkMenu(column: Int, row: Int) {
        makeMarkNSMenu(column: column, row: row).popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

/// A single tile's visual: the real terrain background (T-008) as the base
/// layer, with the real tile-mark interior icon composited centered on top
/// wherever a mark is set. `.unmarked` tiles show terrain alone, undecorated
/// — matching how the reference app's map looks before the player has
/// marked anything.
///
/// **Bugfix, not the original design:** this used to overlay a full-tile
/// icon cropped from `s_icon_overworld_strip39.png`. That file is dead code
/// in the reference app (see `OverworldTileMark.iconSource`'s doc comment)
/// — the real interior icon is much smaller than the tile (5×9 of a 16×11
/// tile) and centered within it, composited from up to three different
/// sources depending on the mark. Position/size fractions below are ported
/// exactly from `Graphics.fs`'s `initFull()` (`:947-960`): interior region
/// is `x∈[5,10), y∈[1,10)` within the 16×11 tile.
/// The fixed fairy-fountain overworld screens (`WPFUI.fs:488-490`): `(9,3)`
/// and `(3,4)` in every quest, plus `(11,0)` in second quest only. Pure +
/// testable. (These coordinates are always-empty in the relevant quests, so
/// the fairy is only ever drawn on an always-empty tile.)
enum OverworldFairySpots {
    static func isFairySpot(column: Int, row: Int, quest: OverworldQuest) -> Bool {
        if column == 9 && row == 3 { return true }
        if column == 3 && row == 4 { return true }
        if quest == .second && column == 11 && row == 0 { return true }
        return false
    }
}

/// Loads the fairy sprite (`icons8x16.png`, 8×16px, the whole image, with
/// black keyed transparent — `Graphics.fs:684-693`).
enum FairyIconAtlas {
    static let image: CGImage? = AtlasLoader.load("icons8x16", blackIsTransparent: true)
}

/// All of a tile's chooser + enemy-picker behavior (T-185) in one modifier, so the
/// per-tile view expression in the grid stays small enough to type-check. Right-click
/// keeps the native text menu in menu mode, or opens the graphical chooser popover in
/// graphical mode; scroll-up (graphical only) opens the enemy picker.
private struct TileChooserModifiers: ViewModifier {
    let graphical: Bool
    let onOpenChooser: () -> Void
    let menu: () -> AnyView
    let chooserPresented: Binding<Bool>
    let chooser: () -> AnyView
    let onScrollUp: () -> Void
    let enemyPresented: Binding<Bool>
    let enemy: () -> AnyView

    func body(content: Content) -> some View {
        rightClickLayer(content)
            .popover(isPresented: chooserPresented, arrowEdge: .bottom) { chooser() }
            .overlay { if graphical { ScrollUpCatcher(onScrollUp: onScrollUp) } }
            .popover(isPresented: enemyPresented, arrowEdge: .top) { enemy() }
    }

    @ViewBuilder
    private func rightClickLayer(_ content: Content) -> some View {
        if graphical {
            content.onRightClick { onOpenChooser() }
        } else {
            content.contextMenu { menu() }
        }
    }
}

/// Internal (not private) so the graphical tile chooser (T-185) can reuse the exact
/// map glyph rendering for its option cells.
struct TileView: View {
    var mark: OverworldTileMark
    var background: CGImage?
    var tileWidth: CGFloat
    var tileHeight: CGFloat
    /// This screen can never contain anything for the current quest
    /// (`OverworldInstance.alwaysEmpty`) — rendered as a permanent, non-
    /// editable darkened "don't care" tile (`WPFUI.fs:244`).
    var isAlwaysEmpty: Bool = false
    /// This always-empty screen is a fixed fairy-fountain spot and shows the
    /// fairy icon (`WPFUI.fs:488-490`).
    var showsFairy: Bool = false
    /// Whether the map is mirrored (T-047). The terrain sprite stays flipped
    /// (the map is genuinely mirrored), but glyph layers — dungeon/any-road
    /// numerals, interior icons, the fairy — are counter-flipped so they read
    /// normally, matching the reference's re-flip of readable elements.
    var mirrored: Bool = false
    /// Hidden Dungeon Numbers (T-049): render dungeon digits 1–8 as A–H.
    var hideDungeonNumbers: Bool = false
    /// This claimable tile has been marked **used** (collected) — T-054;
    /// dimmed with a check so it reads as done.
    var used: Bool = false
    /// A shop tile's second item (T-060); both are drawn in `ShopKind` order.
    var shopSecondItem: ShopKind? = nil
    /// The "Hide tile icons" view control is active (T-062): suppress every
    /// user-placed mark layer (digit badge, interior/shop icon, dark/used
    /// shading) so only the raw terrain (plus always-empty / fairy truth) shows.
    var hideMarks: Bool = false
    /// This tile's dungeon is 100% complete (T-035.6) — its digit/letter badge
    /// dims from bright yellow to dark yellow.
    var dungeonComplete: Bool = false
    /// This marked tile's *kind* is set to hide in "More settings" (T-004.3):
    /// its icon is dimmed on the map, revealed on hover.
    var kindHidden: Bool = false
    /// Custom-map fog-of-war (T-167): this screen is undiscovered, so cover it with
    /// fog until it's revealed (by marking it, or manually).
    var fog: Bool = false
    /// The terrain is painted by one image behind the whole grid (custom maps, T-167),
    /// so this tile must stay transparent instead of drawing its own background.
    var sharedBackground: Bool = false

    /// Reveals a `kindHidden` tile's icon while the pointer is over it (the
    /// reference's `temporarilyDisplayHiddenOverworldTileMarks` peek).
    @State private var revealHovered = false

    /// How faint a hidden-kind tile's icon is when not being hovered — matches
    /// the reference's dark-X dimming (`X_OPACITY`).
    private static let hiddenIconOpacity: CGFloat = 0.28

    private static let interiorOffsetXFraction: CGFloat = 5.0 / 16.0
    private static let interiorOffsetYFraction: CGFloat = 1.0 / 11.0
    private static let interiorWidthFraction: CGFloat = 5.0 / 16.0
    private static let interiorHeightFraction: CGFloat = 9.0 / 11.0

    /// Ported from `Color.Orchid` (`Z1R_WPF/Graphics.fs:886-892`, any-road
    /// digit background) — .NET's standard Orchid RGB value.
    private static let anyRoadBackground = Color(red: 218.0 / 255, green: 112.0 / 255, blue: 214.0 / 255)
    /// The completed-dungeon dark yellow (`RGB(153,153,0)`,
    /// `Graphics.fs:874-884`) — a 100%-complete dungeon's badge dims to this.
    private static let completeDungeonBackground = Color(red: 153.0 / 255, green: 153.0 / 255, blue: 0)
    /// Ported from `itemBackgroundColor` (`Z1R_WPF/Graphics.fs:830`, shop
    /// icon background).
    private static let shopBackground = Color(red: 0xEF / 255.0, green: 0x83 / 255.0, blue: 0)

    var body: some View {
        let _ = perfTrace()
        ZStack(alignment: .topLeading) {
            backgroundView
            // Custom-map fog (T-167): cover undiscovered screens. Drawn over the
            // terrain; an undiscovered screen has no user mark (marking reveals it),
            // so nothing important is hidden.
            if fog {
                fogView.frame(width: tileWidth, height: tileHeight)
            }
            // When "Hide tile icons" is active (T-062), every user-placed mark
            // layer is suppressed so the terrain reads cleanly — only the
            // always-empty / fairy truth below still draws.
            if !hideMarks {
                Group {
                    // .dontCare ("dark") darkens the terrain rather than blacking
                    // it out entirely, so the underlying map stays readable
                    // (aesthetic improvement over the reference's solid-black fill).
                    if mark.iconSource == .solidBlackTile {
                        Rectangle().fill(.black.opacity(0.62))
                    }
                    // Dungeon / any-road numbers render as a larger centered badge
                    // (not confined to the tiny 5px interior-icon region) so they're
                    // legible at map scale.
                    digitBadge
                        .frame(width: tileWidth, height: tileHeight)
                        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                    // Sword caves use the high-fidelity Items-area sword sprite on a
                    // dark plate (like the item boxes), sized like the digit badge
                    // so it reads at map scale — T-063.
                    swordCaveBadge
                        .frame(width: tileWidth, height: tileHeight)
                        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                    // Interior sprites (secrets, door repair, money game, letter,
                    // armos, hint shop, take-any, potion) are enlarged and centered
                    // so they read at map scale, matching the dungeon-number / sword
                    // fidelity — no longer confined to the tiny off-center reference
                    // interior region (T-064, same art, just bigger + centered).
                    interiorSpriteView
                        .frame(width: tileWidth, height: tileHeight)
                        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                    // Shops keep the orange-plate presentation in the reference
                    // interior region (their two 3×7 item icons already read well).
                    shopIconView
                        .frame(width: tileWidth * Self.interiorWidthFraction, height: tileHeight * Self.interiorHeightFraction)
                        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                        .offset(x: tileWidth * Self.interiorOffsetXFraction, y: tileHeight * Self.interiorOffsetYFraction)
                }
                // "More settings" per-kind hiding (T-004.3): dim this tile's mark
                // when its kind is hidden, unless the pointer is over it (peek).
                .opacity(kindHidden && !revealHovered ? Self.hiddenIconOpacity : 1)
                .onHover { revealHovered = $0 }
            }
            // Permanent "always empty" screens are simply darkened (same as a
            // user `.dontCare` mark) — a darkened tile already reads as
            // "nothing here", so no extra glyph. A few of them are fixed
            // fairy-fountain spots, which do get the fairy icon.
            if isAlwaysEmpty {
                Rectangle().fill(.black.opacity(0.62))
                    .frame(width: tileWidth, height: tileHeight)
            }
            // The fairy icon is map truth, not a user mark, so it draws on its own —
            // *not* nested under `isAlwaysEmpty`. Vanilla fairy spots happen to be
            // always-empty screens, but a custom map has no always-empty screens
            // (T-167), so nesting meant a hand-placed fairy never drew.
            if showsFairy, let fairy = FairyIconAtlas.image {
                Image(decorative: fairy, scale: 1, orientation: .up)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: tileHeight * 0.7, height: tileHeight * 0.7)
                    .frame(width: tileWidth, height: tileHeight)
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            }
            // A claimed ("used") tile — or a 100%-complete dungeon (T-035.6) —
            // gets the full-tile dim so it reads as "done" like every other
            // collected tile (the dark-yellow badge alone wasn't enough). The
            // darkened tile + icon convey done, so no extra glyph (T-054).
            // Suppressed with the rest of the mark layers under "Hide tile
            // icons" (T-062).
            if used || dungeonComplete, !hideMarks {
                Rectangle().fill(.black.opacity(0.55))
                    .frame(width: tileWidth, height: tileHeight)
            }
        }
        .frame(width: tileWidth, height: tileHeight)
        .clipped()
        .overlay(Rectangle().stroke(.black.opacity(0.3), lineWidth: 0.5))
    }

    @ViewBuilder
    private var backgroundView: some View {
        if sharedBackground {
            Color.clear
        } else if let background {
            Image(decorative: background, scale: 1, orientation: .up)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle().fill(.gray.opacity(0.3))
        }
    }

    /// The custom-map fog cover (T-167): a dark blue-grey "mist" (not the reference's
    /// checkerboard) with a faint diagonal sheen and a thin grid line on top, so
    /// undiscovered screens read as unexplored while the grid stays visible. Cheap
    /// (gradients only) so it doesn't cost framerate at 128 tiles.
    private var fogView: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color(red: 0.11, green: 0.12, blue: 0.17),
                                          Color(red: 0.04, green: 0.05, blue: 0.09)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(LinearGradient(colors: [.white.opacity(0.05), .clear, .white.opacity(0.03)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Rectangle().strokeBorder(.white.opacity(0.07), lineWidth: 0.5))
    }

    @ViewBuilder
    private var digitBadge: some View {
        switch mark.iconSource {
        case .dungeonDigit(let number):
            // HDN relabels dungeons 1–8 as A–H (Level 9 stays "9"); any-road
            // digits are unaffected. A completed dungeon dims to dark yellow.
            digitIcon(DungeonLabeling.slotLabel(number, hideDungeonNumbers: hideDungeonNumbers),
                      background: dungeonComplete ? Self.completeDungeonBackground : .yellow)
        case .anyRoadDigit(let number):
            digitIcon("\(number)", background: Self.anyRoadBackground)
        case .anyRoadUnknown:
            digitIcon("?", background: Self.anyRoadBackground)
        default:
            EmptyView()
        }
    }

    /// The Items-area sword sprite (wood / white / magical for cave levels
    /// 1 / 2 / 3) — the high-fidelity replacement for the numbered ow sprite.
    private static func swordIcon(forCaveLevel level: Int) -> ItemIconAtlas.Icon? {
        switch level {
        case 1: .brownSword
        case 2: .whiteSword
        case 3: .magicalSword
        default: nil
        }
    }

    @ViewBuilder
    private var swordCaveBadge: some View {
        if case .swordCaveItem(let level) = mark.iconSource,
           let icon = Self.swordIcon(forCaveLevel: level),
           let image = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
            let badge = min(tileWidth, tileHeight) * 0.82
            RoundedRectangle(cornerRadius: badge * 0.18)
                .fill(.black.opacity(0.82))
                .overlay(
                    image.interpolation(.none).resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(badge * 0.14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: badge * 0.18)
                        .strokeBorder(.black.opacity(0.55), lineWidth: 1)
                )
                .frame(width: badge, height: badge)
        }
    }

    /// The plain interior sprites (everything except shops), rendered large and
    /// centered within the tile at their native 5×9 aspect (T-064). `.fit` keeps
    /// the pixel art undistorted; the height cap leaves a small margin so the
    /// sprite doesn't touch the tile border.
    @ViewBuilder
    private var interiorSpriteView: some View {
        if case .interiorSprite(let index) = mark.iconSource {
            switch index {
            // Secret rupee spots: 1 / 2 / 3 five-rupee sprites clustered for
            // small / medium / large (indices 9 / 6 / 8). The money game (10) is a
            // single static orange rupee via the sprite map, so it stays distinct.
            case 9: secretRupees(1)
            case 6: secretRupees(2)
            case 8: secretRupees(3)
            default:
                // Prefer the real game sprite; fall back to the atlas glyph for marks
                // (e.g. the unknown secret) that still have none.
                if let file = GameSprite.overworldFile(index: index), let cg = GameSprite.image(file) {
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .resizable().interpolation(.none).aspectRatio(contentMode: .fit)
                        .frame(width: tileWidth, height: tileHeight * 0.9)
                } else if let icon = OverworldInteriorIconAtlas.icon(at: index) {
                    Image(decorative: icon, scale: 1, orientation: .up)
                        .resizable()
                        .interpolation(.none) // crisp nearest-neighbor, matches the reference's integer scaling
                        .aspectRatio(contentMode: .fit)
                        .frame(width: tileWidth, height: tileHeight * 0.9)
                }
            }
        }
    }

    /// A cluster of `count` five-rupee sprites for a secret-money spot (T-161).
    @ViewBuilder
    private func secretRupees(_ count: Int) -> some View {
        if let cg = GameSprite.image("5 Rupees") {
            HStack(spacing: -tileWidth * 0.05) {
                ForEach(0..<count, id: \.self) { _ in
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .resizable().interpolation(.none).aspectRatio(contentMode: .fit)
                        .frame(height: tileHeight * 0.72)
                }
            }
            .frame(width: tileWidth, height: tileHeight * 0.9)
        }
    }


    @ViewBuilder
    private var shopIconView: some View {
        if case .shopSprite = mark.iconSource {
            let interiorBoxHeight = tileHeight * Self.interiorHeightFraction
            ZStack {
                Self.shopBackground
                // Shops carry up to two items (T-060), drawn side by side in
                // `ShopKind` order for a stable layout.
                HStack(spacing: 0) {
                    ForEach(orderedShopItems, id: \.self) { kind in
                        // Real game sprite (T-161) at its natural aspect; the crude
                        // 3×7 atlas glyph only if a sprite is somehow missing.
                        if let file = GameSprite.shopFile(kind), let cg = GameSprite.image(file) {
                            Image(decorative: cg, scale: 1, orientation: .up)
                                .resizable().interpolation(.none).aspectRatio(contentMode: .fit)
                        } else if let icon = OverworldShopIconAtlas.icon(at: ShopKind.allCases.firstIndex(of: kind) ?? 0) {
                            Image(decorative: icon, scale: 1, orientation: .up)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(3.0 / 7.0, contentMode: .fit)
                        }
                    }
                }
                .padding(.vertical, interiorBoxHeight / 9.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// This shop's items in `ShopKind` display order (primary from the mark +
    /// the second item, deduped) — T-060.
    private var orderedShopItems: [ShopKind] {
        guard case .shop(let first) = mark else { return [] }
        var kinds = [first]
        if let second = shopSecondItem, second != first { kinds.append(second) }
        return kinds.sorted {
            (ShopKind.allCases.firstIndex(of: $0) ?? 0) < (ShopKind.allCases.firstIndex(of: $1) ?? 0)
        }
    }

    /// A centered colored badge with a bold label (a dungeon/any-road number, or
    /// an A–H dungeon letter under HDN), sized to most of the tile so it's
    /// legible at map scale.
    private func digitIcon(_ label: String, background: Color) -> some View {
        let badge = min(tileWidth, tileHeight) * 0.82
        return RoundedRectangle(cornerRadius: badge * 0.18)
            .fill(background)
            .overlay(
                Text(label)
                    .font(.system(size: badge * 0.8, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.3)
                    .foregroundStyle(.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: badge * 0.18)
                    .strokeBorder(.black.opacity(0.55), lineWidth: 1)
            )
            .frame(width: badge, height: badge)
    }
}

/// Loads the reference app's real overworld interior-icon strip
/// (`ow_icons5x9.png`, 14 icons of 5×9px each) and crops individual icons on
/// demand. Covers sword caves, secrets, door repair, money making game, the
/// letter, armos, hint shop, take-any, and the potion shop — grounded in
/// `Graphics.fs`'s `theInteriorBmpTable` construction (`:850-945`) and
/// verified icon-by-icon against the actual strip pixels, not assumed from
/// the filename.
enum OverworldInteriorIconAtlas {
    static let iconWidth = 5
    static let iconHeight = 9
    static let iconCount = 14

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "ow_icons5x9", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage, (0..<iconCount).contains(index) else { return nil }
        let rect = CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight)
        return fullImage.cropping(to: rect)
    }
}

/// Loads the reference app's real shop-item icon strip (`icons3x7.png`, 8
/// icons of 3×7px each — Arrow/Bomb/Book/BlueCandle/BlueRing/Meat/Key/Shield,
/// matching `MapSquareChoiceDomainHelper`'s `ARROW`...`SHIELD` order exactly)
/// and crops individual icons on demand.
enum OverworldShopIconAtlas {
    static let iconWidth = 3
    static let iconHeight = 7
    static let iconCount = 8

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "icons3x7", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage, (0..<iconCount).contains(index) else { return nil }
        let rect = CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight)
        return fullImage.cropping(to: rect)
    }
}

/// Loads the reference app's overworld terrain-art strip once and crops
/// individual 16×11px terrain tiles on demand, per quest (T-008). The
/// source (`s_map_overworld_vanilla_strip8.png`, 1280×88px) is 5
/// horizontal sections of 256×88px each — the first 4 are the real quest
/// layouts (`OverworldQuest.referenceAppIndex`, grounded in
/// `OverworldData.fs`'s `OWQuest.AsInt`), the 5th is unused/blank (the
/// reference app's `OWQuest.BLANK`, which maps to the already-deferred
/// "alternative overworld map" mode — not read here). Each 256×88px section
/// is itself a 16×8 grid of 16×11px tiles, identical in shape to
/// `OverworldIconAtlas`'s icons — confirmed via `Graphics.fs`'s
/// `overworldMapBMPs` pixel-indexing math, not guessed.
enum OverworldBackgroundAtlas {
    static let tileWidth = 16
    static let tileHeight = 11
    static let sectionWidth = tileWidth * OverworldGrid.columnCount // 256
    static let questCount = 4 // FIRST, SECOND, MIXED_FIRST, MIXED_SECOND -- BLANK excluded, see above

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "s_map_overworld_vanilla_strip8", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func tile(quest: OverworldQuest, column: Int, row: Int) -> CGImage? {
        guard
            let fullImage,
            (0..<OverworldGrid.columnCount).contains(column),
            (0..<OverworldGrid.rowCount).contains(row)
        else { return nil }
        let sectionX = quest.referenceAppIndex * sectionWidth
        let rect = CGRect(
            x: sectionX + column * tileWidth,
            y: row * tileHeight,
            width: tileWidth,
            height: tileHeight
        )
        return fullImage.cropping(to: rect)
    }
}

/// Draws the hover-triggered route lines (T-011) on top of the grid, using
/// coordinates computed as a *fraction* of each tile's current on-screen
/// size — the reference app's `coords` function
/// (`OverworldRouteDrawing.fs:72-80`) uses fixed absolute pixel offsets into
/// a fixed-size `Canvas`, which doesn't hold up under this app's responsive,
/// reflowing layout (`docs/decisions/0003-responsive-layout-not-fixed-presets.md`);
/// this recomputes from the actual current `tileWidth`/`tileHeight` every
/// layout pass instead.
private struct OverworldRouteLinesOverlay: View {
    var lines: [OverworldRouteLineSegment]
    var tileWidth: CGFloat
    var tileHeight: CGFloat

    var body: some View {
        let _ = perfTrace()
        Canvas { context, _ in
            for line in lines {
                var path = Path()
                path.move(to: point(for: line.from))
                path.addLine(to: point(for: line.to))
                context.stroke(path, with: .color(color(forCost: line.cost)), lineWidth: 2)
            }
        }
    }

    private func point(for vertex: OverworldVertex) -> CGPoint {
        let offset = OverworldRouteGeometry.fractionalOffset(for: vertex.portion)
        return CGPoint(
            x: (CGFloat(vertex.x) + offset.x) * tileWidth,
            y: (CGFloat(vertex.y) + offset.y) * tileHeight
        )
    }

    /// Opacity tiers ported from `OverworldRouteDrawing.fs`'s `color(cost)`
    /// function (`:130-137`) — a white line, brightest near the hovered
    /// tile, fading as path cost increases.
    private func color(forCost cost: Int) -> Color {
        if cost <= 8 { .white.opacity(0.706) }
        else if cost <= 14 { .white.opacity(0.588) }
        else if cost <= 22 { .white.opacity(0.47) }
        else if cost <= 30 { .white.opacity(0.392) }
        else { .white.opacity(0.333) }
    }
}

/// Where each screen portion sits within its own tile's bounds, as a
/// fraction of tile width/height — converted from the reference app's
/// absolute-pixel offsets (`OverworldRouteDrawing.fs:72-80`: tile is 48×33px
/// at the reference's fixed 3x zoom, offsets are `8*3`/`5*3` for center and
/// `±4`/`±6`/`±8`/`±12` for the half-screen portions) so the same relative
/// layout holds at any tile size.
private enum OverworldRouteGeometry {
    static func fractionalOffset(for portion: OverworldScreenPortion) -> (x: CGFloat, y: CGFloat) {
        switch portion {
        case .full: (0.5, 0.5)
        case .north: (0.5 + 4.0 / 48.0, 0.5 - 8.0 / 33.0)
        case .south: (0.5 - 6.0 / 48.0, 0.5 + 8.0 / 33.0)
        case .east: (0.5 + 12.0 / 48.0, 0.5)
        case .west: (0.5 - 12.0 / 48.0, 0.5)
        }
    }
}

#Preview {
    let grid = OverworldGrid()
    let playerState = PlayerComputedStateSummary(haveLadder: true, haveRaft: true)
    OverworldMapView(
        grid: grid,
        quest: .first,
        options: TrackerOptions(),
        focus: TrackerFocusState(),
        playerState: playerState,
        mapState: MapStateSummary.compute(
            grid: grid,
            instance: OverworldInstance(quest: .first),
            dungeonTracker: DungeonTrackerInstance(),
            playerState: playerState,
            progress: PlayerProgressAndTakeAnyHearts(),
            drawRoutes: true,
            routesCanScreenScroll: false,
            mirrorOverworld: false
        ),
        dungeonTracker: DungeonTrackerInstance()
    )
    .frame(width: 800)
    .padding()
}
